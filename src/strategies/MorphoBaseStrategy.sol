// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IMorphoStaticTyping, Id, MarketParams } from "../interfaces/vendors/IMorpho.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/utils/ReentrancyGuard.sol";

import { IMorphoBaseStrategy } from "../interfaces/strategies/IMorphoBaseStrategy.sol";

import { Utils } from "../Utils.sol";

contract MorphoBaseStrategy is ReentrancyGuard, IMorphoBaseStrategy {
    using SafeERC20 for IERC20;

    address s_morpho;
    mapping(address user => mapping(Id marketId => uint256 shares)) private s_shares;

    constructor(address _morpho) {
        s_morpho = _morpho;
    }

    function deposit(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData
    )
        external
        nonReentrant
        returns (bool)
    {
        Utils.requireLengthsMatch(_tokens.length, _amounts.length);
        _validateAndManageInputTokenAmounts(_tokens, _amounts);

        Id marketId = abi.decode(_additionalData, (Id));
        MarketParams memory marketParams = _getMarketParams(marketId);
        if (marketParams.loanToken != _tokens[0]) revert MorphoBaseStrategy__NotLoanTokenForMarket();
        (, uint256 sharesReceived) =
            IMorphoStaticTyping(s_morpho).supply(marketParams, _amounts[0], 0, address(this), "");

        s_shares[msg.sender][marketId] += sharesReceived;

        emit DepsoitedIntoMorpho(msg.sender, marketId, sharesReceived);

        return true;
    }

    function withdraw(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _to
    )
        external
        nonReentrant
        returns (bool)
    {
        (Id marketId, uint256 sharesToBurn) = abi.decode(_additionalData, (Id, uint256));
        uint256 amount = sharesToBurn > 0 ? 0 : _amounts[0];

        MarketParams memory marketParams = _getMarketParams(marketId);
        if (marketParams.loanToken != _tokens[0]) revert MorphoBaseStrategy__NotLoanTokenForMarket();
        (, uint256 sharesBurned) =
            IMorphoStaticTyping(s_morpho).withdraw(marketParams, amount, sharesToBurn, address(this), _to);

        s_shares[msg.sender][marketId] -= sharesBurned;

        emit WithdrawnFromMorpho(msg.sender, marketId, sharesBurned, _to);

        return true;
    }

    function _validateAndManageInputTokenAmounts(address[] calldata _tokens, uint256[] calldata _amounts) internal {
        address morpho = s_morpho;
        uint256 length = _tokens.length;

        for (uint256 i; i < length; ++i) {
            Utils.requireNotAddressZero(_tokens[i]);
            Utils.requireNotValueZero(_amounts[i]);

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

    function getMorpho() external view returns (address) {
        return s_morpho;
    }

    function getMarketSharesForUser(address _user, Id _marketId) external view returns (uint256) {
        return s_shares[_user][_marketId];
    }
}
