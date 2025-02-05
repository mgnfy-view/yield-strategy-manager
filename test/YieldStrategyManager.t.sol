// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { YieldStrategyManager } from "../src/YieldStrategyManager.sol";
import { Test, console } from "@forge/Test.sol";

contract YieldStrategyManagerTest is Test {
    function test_healthCheck() external pure {
        assertEq(uint256(1), uint256(1));
    }
}
