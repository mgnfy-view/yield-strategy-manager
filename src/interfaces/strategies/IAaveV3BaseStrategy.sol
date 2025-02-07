// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IStrategy } from "../IStrategy.sol";

interface IAaveV3BaseStrategy is IStrategy {
    event DepositedIntoAave(address indexed user, address indexed token, uint256 indexed aTokensReceived);
    event WithdrawnFromAave(address indexed by, address indexed token, uint256 indexed amount, address to);

    error AaveV3BaseStrategy__NotYieldStrategyManager();
    error AaveV3BaseStrategy__InsufficientAmountToWitdraw();

    function getPool() external view returns (address);
    function getATokenBalance(address _user, address _asset) external view returns (uint256);
}
