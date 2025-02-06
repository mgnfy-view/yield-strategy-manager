// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Test, console } from "@forge/Test.sol";

import { IYieldStrategyManager } from "../src/interfaces/IYieldStrategyManager.sol";

import { Utils } from "../src/Utils.sol";
import { YieldStrategyManager } from "../src/YieldStrategyManager.sol";

contract YieldStrategyManagerTest is Test {
    address admin;

    YieldStrategyManager public manager;

    function setUp() external {
        admin = makeAddr("admin");

        manager = new YieldStrategyManager(admin);
    }

    function test_whitelistingAddressZeroStrategyFails() external {
        vm.startPrank(admin);
        vm.expectRevert(Utils.Utils__AddressZero.selector);
        manager.whitelistStrategy(address(0));
        vm.stopPrank();
    }

    function test_whitelistingStrategySucceeds() external {
        address newStrategy = makeAddr("new strategy");

        vm.startPrank(admin);
        manager.whitelistStrategy(newStrategy);
        vm.stopPrank();

        address[] memory whitelistedStrategies = manager.getAllStrategies();

        assertEq(whitelistedStrategies.length, 1);
        assertEq(whitelistedStrategies[0], newStrategy);
    }

    function test_whitelistingStrategyEmitsEvent() external {
        address newStrategy = makeAddr("new strategy");

        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit IYieldStrategyManager.WhitelistedStrategy(newStrategy);
        manager.whitelistStrategy(newStrategy);
        vm.stopPrank();
    }

    function test_removingNonWhitelistedStrategyFails() external {
        address strategy = makeAddr("strategy");

        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategyManager.YieldStrategyManager__NotWhitelistedStrategy.selector, strategy
            )
        );
        manager.removeStrategy(strategy);
        vm.stopPrank();
    }

    function test_removingStrategySucceeds() external {
        address newStrategy = makeAddr("new strategy");

        _addStrategy(newStrategy);

        vm.startPrank(admin);
        manager.removeStrategy(newStrategy);
        vm.stopPrank();

        address[] memory whitelistedStrategies = manager.getAllStrategies();

        assertEq(whitelistedStrategies.length, 0);
    }

    function test_removingStrategyEmitsEvent() external {
        address newStrategy = makeAddr("new strategy");

        _addStrategy(newStrategy);

        vm.startPrank(admin);
        vm.expectEmit(true, false, false, false);
        emit IYieldStrategyManager.RemovedStrategyFromWhitelist(newStrategy);
        manager.removeStrategy(newStrategy);
        vm.stopPrank();
    }

    function _addStrategy(address _newStrategy) internal {
        vm.startPrank(admin);
        manager.whitelistStrategy(_newStrategy);
        vm.stopPrank();
    }
}
