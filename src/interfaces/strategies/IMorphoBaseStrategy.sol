// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Id } from "../vendors/IMorpho.sol";

import { IStrategy } from "../IStrategy.sol";

interface IMorphoBaseStrategy is IStrategy {
    event DepsoitedIntoMorpho(address indexed by, Id indexed marketId, uint256 indexed sharesReceived);
    event WithdrawnFromMorpho(address by, Id indexed marketId, uint256 indexed sharesBurned, address indexed to);

    error MorphoBaseStrategy__NotLoanTokenForMarket();
}
