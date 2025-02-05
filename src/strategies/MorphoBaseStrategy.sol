// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IMorphoStaticTyping, Id, MarketParams } from "../interfaces/vendors/morpho/IMorpho.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import { IMorphoBaseStrategy } from "../interfaces/strategies/IMorphoBaseStrategy.sol";

import { Utils } from "../Utils.sol";

contract MorphoBaseStrategy is IMorphoBaseStrategy {
    using SafeERC20 for IERC20;

    address private s_yieldStrategyManager;
    address private s_morpho;
    mapping(address user => mapping(Id marketId => uint256 shares)) private s_shares;

    modifier onlyYieldStrategyManager() {
        if (msg.sender != s_yieldStrategyManager) revert MorphoBaseStrategy__NotYieldStrategyManager();
        _;
    }

    constructor(address _yieldStrategyManager, address _morpho) {
        s_yieldStrategyManager = _yieldStrategyManager;
        s_morpho = _morpho;
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

        Id marketId = abi.decode(_additionalData, (Id));
        MarketParams memory marketParams = _getMarketParams(marketId);
        if (marketParams.loanToken != _tokens[0]) revert MorphoBaseStrategy__NotLoanTokenForMarket();
        (, uint256 sharesReceived) =
            IMorphoStaticTyping(s_morpho).supply(marketParams, _amounts[0], 0, address(this), "");

        s_shares[_for][marketId] += sharesReceived;

        emit DepositedIntoMorpho(_for, marketId, sharesReceived);

        return true;
    }

    function withdraw(
        address _by,
        address[] calldata _tokens,
        uint256[] memory _amounts,
        bytes calldata _additionalData,
        address _to
    )
        external
        onlyYieldStrategyManager
        returns (bool)
    {
        Utils.requireExactlyOne(_tokens.length);
        Utils.requireLengthsMatch(_tokens.length, _amounts.length);
        Utils.requireNotAddressZero(_to);

        (Id marketId, uint256 sharesToBurn) = abi.decode(_additionalData, (Id, uint256));
        _amounts[0] = sharesToBurn > 0 ? 0 : _amounts[0];

        MarketParams memory marketParams = _getMarketParams(marketId);
        if (marketParams.loanToken != _tokens[0]) revert MorphoBaseStrategy__NotLoanTokenForMarket();
        (, uint256 sharesBurned) =
            IMorphoStaticTyping(s_morpho).withdraw(marketParams, _amounts[0], sharesToBurn, address(this), _to);

        s_shares[_by][marketId] -= sharesBurned;

        emit WithdrawnFromMorpho(_by, marketId, sharesBurned, _to);

        return true;
    }

    function _validateAndManageInputTokenAmounts(address[] calldata _tokens, uint256[] calldata _amounts) internal {
        address morpho = s_morpho;
        uint256 length = _tokens.length;

        for (uint256 i; i < length; ++i) {
            Utils.requireNotAddressZero(_tokens[i]);
            Utils.requireNotValueZero(_amounts[i]);

            IERC20(_tokens[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
            IERC20(_tokens[i]).approve(morpho, _amounts[i]);
        }
    }

    function _getMarketParams(Id _marketId) internal view returns (MarketParams memory) {
        IMorphoStaticTyping morpho = IMorphoStaticTyping(s_morpho);

        (address loanToken, address collateralToken, address oracle, address irm, uint256 lltv) =
            morpho.idToMarketParams(_marketId);
        return MarketParams({
            loanToken: loanToken,
            collateralToken: collateralToken,
            oracle: oracle,
            irm: irm,
            lltv: lltv
        });
    }

    function getYieldStrategyManager() external view returns (address) {
        return s_yieldStrategyManager;
    }

    function getMorpho() external view returns (address) {
        return s_morpho;
    }

    function getMarketSharesForUser(address _user, Id _marketId) external view returns (uint256) {
        return s_shares[_user][_marketId];
    }
}
