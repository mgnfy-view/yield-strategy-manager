// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/utils/ReentrancyGuard.sol";

import { IAaveV3BaseStrategy } from "../interfaces/strategies/IAaveV3BaseStrategy.sol";
import { IPool } from "../interfaces/vendors/aaveV3/IPool.sol";

import { Strategy } from "../Strategy.sol";
import { Utils } from "../Utils.sol";

/// @title AaveV3BaseStrategy.
/// @author mgnfy-view.
/// @notice A simple strategy that lends tokens on Aave to earn interest.
contract AaveV3BaseStrategy is IAaveV3BaseStrategy, Strategy {
    using SafeERC20 for IERC20;

    uint256 private constant E27 = 1e27;

    /// @dev The Aave V3 pool address.
    address private immutable i_pool;
    /// @dev Mapping to track user positions.
    mapping(address user => mapping(address asset => uint256 aTokens)) private s_aTokenBalance;

    /// @notice Sets the yield strategy manager and Aave V3 pool addresses.
    /// @param _yieldStrategyManager The yield strategy manager contract.
    /// @param _pool The Aave V3 pool address.
    constructor(address _yieldStrategyManager, address _pool) Strategy(_yieldStrategyManager) {
        i_pool = _pool;
    }

    /// @notice Supplies an input token to Aave V3 and receives aTokens which are tracked per user.
    /// @param _tokens A set of tokens to supply. Only one token should be passed.
    /// @param _amounts The token amounts to provide. Only one amount should be passed.
    /// @param _additionalData The referral code. Optional. Pass abi.encode(0) as default.
    /// @param _for The user to open the strategy on behalf of.
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
        _manageInputTokenAmounts(_tokens, _amounts);

        IPool aavePool = IPool(i_pool);
        address aToken = aavePool.getReserveData(_tokens[0]).aTokenAddress;
        uint16 referralCode = abi.decode(_additionalData, (uint16));
        uint256 aTokenBalanceBefore = IERC20(aToken).balanceOf(address(this));

        aavePool.supply(_tokens[0], _amounts[0], address(this), referralCode);

        uint256 aTokensReceived = IERC20(aToken).balanceOf(address(this)) - aTokenBalanceBefore;
        s_aTokenBalance[_for][_tokens[0]] += aTokensReceived;

        emit DepositedIntoAave(_for, _tokens[0], aTokensReceived);

        return true;
    }

    /// @notice Withdraws the deposited tokens by burning the aTokens.
    /// @param _by The user whose position is to be used for withdrawal.
    /// @param _tokens A set of tokens to withdraw. Only one token should be passed.
    /// @param _amounts The token amounts to withdraw. Only one amount should be passed.
    /// @param _to The address to direct the withdrawn amount to.
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

        IPool aavePool = IPool(i_pool);
        _revertIfInsufficientAmountToWithdraw(aavePool, _tokens[0], _by, _amounts[0]);

        s_aTokenBalance[_by][_tokens[0]] -= _amounts[0];
        aavePool.withdraw(_tokens[0], _amounts[0], _to);

        emit WithdrawnFromAave(_by, _tokens[0], _amounts[0], _to);

        return true;
    }

    /// @notice Approves the input token to Aave V3 before calling `aaveV3Pool.supply()`.
    /// @param _tokens The tokens to approve. Only the first token in the array is managed.
    /// @param _amounts The amounts to apporve. Only the first amount in the array is used.
    function _manageInputTokenAmounts(address[] calldata _tokens, uint256[] calldata _amounts) internal {
        address aavePool = i_pool;
        uint256 length = _tokens.length;

        for (uint256 i; i < length; ++i) {
            IERC20(_tokens[i]).approve(aavePool, _amounts[i]);
        }
    }

    /// @notice Reverts if the amount to withdraw for is less than the user's balance.
    /// @param _pool The Aave V3 pool.
    /// @param _asset The asset to withdraw.
    /// @param _user The user address.
    /// @param _amountToWithdraw The amount to withdraw from Aave V3.
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

    /// @notice Gets the Aave V3 pool address.
    function getPool() external view returns (address) {
        return i_pool;
    }

    /// @notice Gets the aToken balance of a user in their position.
    /// @param _user The user address.
    /// @param _asset The token address.
    function getATokenBalance(address _user, address _asset) external view returns (uint256) {
        return s_aTokenBalance[_user][_asset];
    }
}
