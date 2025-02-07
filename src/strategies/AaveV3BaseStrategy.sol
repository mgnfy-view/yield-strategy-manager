// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/utils/ReentrancyGuard.sol";

import { IAaveV3BaseStrategy } from "../interfaces/strategies/IAaveV3BaseStrategy.sol";
import { IPool } from "../interfaces/vendors/aaveV3/IPool.sol";

import { Strategy } from "../Strategy.sol";
import { Utils } from "../Utils.sol";

contract AaveV3BaseStrategy is IAaveV3BaseStrategy, Strategy {
    using SafeERC20 for IERC20;

    uint256 private constant E27 = 1e27;

    address private s_pool;
    mapping(address user => mapping(address asset => uint256 aTokens)) private s_aTokenBalance;

    constructor(address _yieldStrategyManager, address _pool) Strategy(_yieldStrategyManager) {
        s_pool = _pool;
    }

    function deposit(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _for
    )
        external
        onlyYieldStrategyManager
        returns (bool)
    {
        Utils.requireExactlyOne(_tokens.length);
        Utils.requireLengthsMatch(_tokens.length, _amounts.length);
        Utils.requireNotAddressZero(_for);
        _validateAndManageInputTokenAmounts(_tokens, _amounts);

        IPool aavePool = IPool(s_pool);
        address aToken = aavePool.getReserveData(_tokens[0]).aTokenAddress;
        uint16 referralCode = abi.decode(_additionalData, (uint16));
        uint256 aTokenBalanceBefore = IERC20(aToken).balanceOf(address(this));

        aavePool.supply(_tokens[0], _amounts[0], address(this), referralCode);

        uint256 aTokensReceived = IERC20(aToken).balanceOf(address(this)) - aTokenBalanceBefore;
        s_aTokenBalance[_for][_tokens[0]] += aTokensReceived;

        emit DepositedIntoAave(_for, _tokens[0], aTokensReceived);

        return true;
    }

    function withdraw(
        address _by,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata, /* _additionalData */
        address _to
    )
        external
        onlyYieldStrategyManager
        returns (bool)
    {
        Utils.requireExactlyOne(_tokens.length);
        Utils.requireLengthsMatch(_tokens.length, _amounts.length);
        Utils.requireNotAddressZero(_to);

        IPool aavePool = IPool(s_pool);
        _revertIfInsufficientAmountToWithdraw(aavePool, _tokens[0], _by, _amounts[0]);

        s_aTokenBalance[_by][_tokens[0]] -= _amounts[0];
        aavePool.withdraw(_tokens[0], _amounts[0], _to);

        emit WithdrawnFromAave(_by, _tokens[0], _amounts[0], _to);

        return true;
    }

    function _validateAndManageInputTokenAmounts(address[] calldata _tokens, uint256[] calldata _amounts) internal {
        address aavePool = s_pool;
        uint256 length = _tokens.length;

        for (uint256 i; i < length; ++i) {
            Utils.requireNotAddressZero(_tokens[i]);
            Utils.requireNotValueZero(_amounts[i]);

            IERC20(_tokens[i]).approve(aavePool, _amounts[i]);
        }
    }

    function _revertIfInsufficientAmountToWithdraw(
        IPool _pool,
        address _asset,
        address _user,
        uint256 _amountToWithdraw
    )
        internal
        view
    {
        uint256 liquidityIndex = _pool.getReserveNormalizedIncome(_asset);
        uint256 withdrawableAmount = (s_aTokenBalance[_user][_asset] * liquidityIndex) / E27;

        if (_amountToWithdraw > withdrawableAmount) revert AaveV3BaseStrategy__InsufficientAmountToWitdraw();
    }

    function getPool() external view returns (address) {
        return s_pool;
    }

    function getATokenBalance(address _user, address _asset) external view returns (uint256) {
        return s_aTokenBalance[_user][_asset];
    }
}
