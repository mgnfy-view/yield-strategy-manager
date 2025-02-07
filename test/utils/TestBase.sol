// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test, console } from "@forge/Test.sol";

import { IYieldStrategyManager } from "../../src/interfaces/IYieldStrategyManager.sol";

import { Utils } from "../../src/Utils.sol";
import { YieldStrategyManager } from "../../src/YieldStrategyManager.sol";

abstract contract TestBase is Test {
    address public admin;
    address public user;

    YieldStrategyManager public manager;

    error TestBase__UnsupportedChain();

    function setUp() public virtual {
        admin = makeAddr("admin");
        user = makeAddr("user");

        manager = new YieldStrategyManager(admin);
    }

    function _addStrategy(address _newStrategy) internal {
        vm.prank(admin);
        manager.whitelistStrategy(_newStrategy);
    }
}
