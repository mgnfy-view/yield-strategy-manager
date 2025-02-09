// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IMorphoStaticTyping, Id, MarketParams } from "../interfaces/vendors/morpho/IMorpho.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import { IMorphoBaseStrategy } from "../interfaces/strategies/IMorphoBaseStrategy.sol";

import { Strategy } from "../Strategy.sol";
import { Utils } from "../Utils.sol";

/// @title MorphoBaseStrategy.
/// @author mgnfy-view.
/// @notice A simple strategy that lends tokens on Morpho to earn interest.
contract MorphoBaseStrategy is IMorphoBaseStrategy, Strategy {
    using SafeERC20 for IERC20;

    /// @dev The Morpho singleton address.
    address private immutable i_morpho;
    /// @dev Mapping to track user positions.
    mapping(address user => mapping(Id marketId => uint256 shares)) private s_shares;

    /// @notice Sets the yield strategy manager and the Morpho singleton addresses.
    /// @param _yieldStrategyManager The yield strategy manager contract.
    /// @param _morpho The Morpho singleton address.
    constructor(address _yieldStrategyManager, address _morpho) Strategy(_yieldStrategyManager) {
        i_morpho = _morpho;
    }

    /// @notice Supplies an input token to Morpho Blue and receives aTokens which are tracked per user.
    /// @param _tokens A set of tokens to supply. Only one token should be passed.
    /// @param _amounts The token amounts to provide. Only one amount should be passed.
    /// @param _additionalData The market Id to supply the tokens to.
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

        Id marketId = abi.decode(_additionalData, (Id));
        MarketParams memory marketParams = _getMarketParams(marketId);
        if (marketParams.loanToken != _tokens[0]) revert MorphoBaseStrategy__NotLoanTokenForMarket();
        (, uint256 sharesReceived) =
            IMorphoStaticTyping(i_morpho).supply(marketParams, _amounts[0], 0, address(this), "");

        s_shares[_for][marketId] += sharesReceived;

        emit DepositedIntoMorpho(_for, marketId, sharesReceived);

        return true;
    }

    /// @notice Withdraws the deposited tokens by burning shares on Morpho.
    /// @param _by The user whose position is to be used for withdrawal.
    /// @param _tokens A set of tokens to withdraw. Only one token should be passed.
    /// @param _amounts The token amounts to withdraw. Only one amount should be passed.
    /// @param _additionalData The amount of shares to burn. Optional. If passed, `_amounts[0]`
    /// will be ignored.
    /// @param _to The address to direct the withdrawn amount to.
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

        (Id marketId, uint256 sharesToBurn) = abi.decode(_additionalData, (Id, uint256));
        _amounts[0] = sharesToBurn > 0 ? 0 : _amounts[0];

        MarketParams memory marketParams = _getMarketParams(marketId);
        if (marketParams.loanToken != _tokens[0]) revert MorphoBaseStrategy__NotLoanTokenForMarket();
        (, uint256 sharesBurned) =
            IMorphoStaticTyping(i_morpho).withdraw(marketParams, _amounts[0], sharesToBurn, address(this), _to);

        s_shares[_by][marketId] -= sharesBurned;

        emit WithdrawnFromMorpho(_by, marketId, sharesBurned, _to);

        return true;
    }

    /// @notice Approves the input token to Morpho before calling `morpho.supply()`.
    /// @param _tokens The tokens to approve. Only the first token in the array is managed.
    /// @param _amounts The amounts to apporve. Only the first amount in the array is used.
    function _manageInputTokenAmounts(address[] calldata _tokens, uint256[] calldata _amounts) internal {
        address morpho = i_morpho;
        uint256 length = _tokens.length;

        for (uint256 i; i < length; ++i) {
            IERC20(_tokens[i]).approve(morpho, _amounts[i]);
        }
    }

    /// @notice Gets the market parameters based on the input market Id.
    /// @param _marketId The given market Id.
    function _getMarketParams(Id _marketId) internal view returns (MarketParams memory) {
        IMorphoStaticTyping morpho = IMorphoStaticTyping(i_morpho);

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

    /// @notice gets the Morpho singleton address.
    function getMorpho() external view returns (address) {
        return i_morpho;
    }

    /// @notice Gets the share balance of a user in their position.
    /// @param _user The user address.
    /// @param _marketId The Id of the lending pool.
    function getMarketSharesForUser(address _user, Id _marketId) external view returns (uint256) {
        return s_shares[_user][_marketId];
    }
}
