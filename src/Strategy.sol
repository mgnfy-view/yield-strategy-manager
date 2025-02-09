// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IStrategy } from "./interfaces/IStrategy.sol";

/// @title Strategy.
/// @author mgnfy-view.
/// @notice The base strategy abstract contract to be inherited by all strategies.
abstract contract Strategy is IStrategy {
    /// @dev The yield strategy manager address.
    address internal immutable i_yieldStrategyManager;

    modifier onlyYieldStrategyManager() {
        _;
    }

    /// @notice Sets the yield strategy manager address.
    /// @param _yieldStrategyManager The yield strategy manager address.
    constructor(address _yieldStrategyManager) {
        i_yieldStrategyManager = _yieldStrategyManager;
    }

    /// @notice Gets the yield strategy manager address.
    function getYieldStrategyManager() external view returns (address) {
        return i_yieldStrategyManager;
    }
}
