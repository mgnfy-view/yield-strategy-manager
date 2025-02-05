// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Id } from "../vendors/morpho/IMorpho.sol";

import { IStrategy } from "../IStrategy.sol";

interface IMorphoBaseStrategy is IStrategy {
    event DepsoitedIntoMorpho(address indexed by, Id indexed marketId, uint256 indexed sharesReceived);
    event WithdrawnFromMorpho(address by, Id indexed marketId, uint256 indexed sharesBurned, address indexed to);

    error MorphoBaseStrategy__NotLoanTokenForMarket();

    function getMorpho() external view returns (address);
    function getMarketSharesForUser(address _user, Id _marketId) external view returns (uint256);
}
