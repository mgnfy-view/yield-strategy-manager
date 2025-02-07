// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IStrategy } from "./interfaces/IStrategy.sol";

abstract contract Strategy is IStrategy {
    address internal immutable i_yieldStrategyManager;

    modifier onlyYieldStrategyManager() {
        _;
    }

    constructor(address _yieldStrategyManager) {
        i_yieldStrategyManager = _yieldStrategyManager;
    }

    function getYieldStrategyManager() external view returns (address) {
        return i_yieldStrategyManager;
    }
}
