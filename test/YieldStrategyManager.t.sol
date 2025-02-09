// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IYieldStrategyManager } from "../src/interfaces/IYieldStrategyManager.sol";

import { Utils } from "../src/Utils.sol";
import { YieldStrategyManager } from "../src/YieldStrategyManager.sol";
import { ERC20Mintable } from "./mocks/ERC20Mintable.sol";
import { MockStrategy } from "./mocks/MockStrategy.sol";
import { TestBase } from "./utils/TestBase.sol";

contract YieldStrategyManagerTest is TestBase {
    MockStrategy public strategy;

    ERC20Mintable public token;

    function setUp() public override {
        super.setUp();

        strategy = new MockStrategy(address(manager));

        string memory name = "Dai";
        string memory symbol = "DAI";
        token = new ERC20Mintable(name, symbol);

        _addStrategy(address(strategy));
    }

    function test_whitelistingAddressZeroStrategyFails() external {
        vm.prank(admin);
        vm.expectRevert(Utils.Utils__AddressZero.selector);
        manager.whitelistStrategy(address(0));
    }

    function test_whitelistingStrategySucceeds() external {
        address newStrategy = makeAddr("new strategy");

        vm.startPrank(admin);
        manager.whitelistStrategy(newStrategy);
        vm.stopPrank();

        address[] memory whitelistedStrategies = manager.getAllStrategies();

        assertEq(whitelistedStrategies.length, 2);
        assertEq(whitelistedStrategies[1], newStrategy);
    }

    function test_whitelistingStrategyEmitsEvent() external {
        address newStrategy = makeAddr("new strategy");

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit IYieldStrategyManager.WhitelistedStrategy(newStrategy);
        manager.whitelistStrategy(newStrategy);
    }

    function test_removingNonWhitelistedStrategyFails() external {
        address nonWhitelistedStrategy = makeAddr("non-whitelisted strategy");

        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategyManager.YieldStrategyManager__NotWhitelistedStrategy.selector, nonWhitelistedStrategy
            )
        );
        manager.removeStrategy(nonWhitelistedStrategy);
    }

    function test_removingStrategySucceeds() external {
        address newStrategy = makeAddr("new strategy");

        _addStrategy(newStrategy);

        vm.startPrank(admin);
        manager.removeStrategy(newStrategy);
        vm.stopPrank();

        address[] memory whitelistedStrategies = manager.getAllStrategies();

        assertEq(whitelistedStrategies.length, 1);
    }

    function test_removingStrategyEmitsEvent() external {
        address newStrategy = makeAddr("new strategy");

        _addStrategy(newStrategy);

        vm.prank(admin);
        vm.expectEmit(true, false, false, false);
        emit IYieldStrategyManager.RemovedStrategyFromWhitelist(newStrategy);
        manager.removeStrategy(newStrategy);
    }

    function test_settingOperatorFailsForNonWhitelistedStrategy() external {
        address nonWhitelistedStrategy = makeAddr("non whitelisted strategy");
        address operator = makeAddr("operator");

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategyManager.YieldStrategyManager__NotWhitelistedStrategy.selector, nonWhitelistedStrategy
            )
        );
        manager.setOperator(nonWhitelistedStrategy, operator, true);
    }

    function test_settingOperatorFailsForAddressZeroOperator() external {
        vm.prank(user);
        vm.expectRevert(Utils.Utils__AddressZero.selector);
        manager.setOperator(address(strategy), address(0), true);
    }

    function test_settingOperatorSucceeds() external {
        address operator = makeAddr("operator");

        _addOperator(address(strategy), operator);

        assertEq(manager.getOperator(address(strategy), user), operator);
    }

    function test_settingOperatorEmitsEvent() external {
        address operator = makeAddr("operator");

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit IYieldStrategyManager.OperatorSet(user, address(strategy), operator, true);
        manager.setOperator(address(strategy), operator, true);

        assertEq(manager.getOperator(address(strategy), user), operator);
    }

    function test_removingOperatorSucceeds() external {
        address operator = makeAddr("operator");

        _addOperator(address(strategy), operator);

        vm.prank(user);
        manager.setOperator(address(strategy), operator, false);

        assertEq(manager.getOperator(address(strategy), user), address(0));
    }

    function test_removingOperatorEmitsEvent() external {
        address operator = makeAddr("operator");

        _addOperator(address(strategy), operator);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit IYieldStrategyManager.OperatorSet(user, address(strategy), operator, false);
        manager.setOperator(address(strategy), operator, false);

        assertEq(manager.getOperator(address(strategy), user), address(0));
    }

    function test_depositingIntoStrategyFailsForNonWhitelistedStrategy() external {
        address nonWhitelistedStrategy = makeAddr("non whitelisted strategy");

        address[] memory tokens = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategyManager.YieldStrategyManager__NotWhitelistedStrategy.selector, nonWhitelistedStrategy
            )
        );
        manager.deposit(nonWhitelistedStrategy, tokens, amounts, "", user);
    }

    function test_depositingIntoStrategyFailsForArrayLengthMismatch() external {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](0);

        tokens[0] = address(token);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Utils.Utils__LengthsDoNotMatch.selector, 1, 0));
        manager.deposit(address(strategy), tokens, amounts, "", user);
    }

    function test_depositingIntoStrategyFailsIfForIsAddressZero() external {
        address[] memory tokens = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.prank(user);
        vm.expectRevert(Utils.Utils__AddressZero.selector);
        manager.deposit(address(strategy), tokens, amounts, "", address(0));
    }

    function test_depositingIntoStrategyFailsIfTokenIsAddressZero() external {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(0);

        vm.prank(user);
        vm.expectRevert(Utils.Utils__AddressZero.selector);
        manager.deposit(address(strategy), tokens, amounts, "", user);
    }

    function test_depositingIntoStrategyFailsIfTokenAmountIsZero() external {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(token);
        amounts[0] = 0;

        vm.prank(user);
        vm.expectRevert(Utils.Utils__ValueZero.selector);
        manager.deposit(address(strategy), tokens, amounts, "", user);
    }

    function test_depositingIntoStrategySucceeds() external {
        uint256 depositAmount = 100e18;

        _depositIntoMockStrategy(depositAmount);

        assertEq(token.balanceOf(address(strategy)), depositAmount);
    }

    function test_depositingIntoStrategyEmitsEvent() external {
        uint256 depositAmount = 100e18;

        deal(address(token), user, depositAmount);

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(token);
        amounts[0] = depositAmount;

        vm.startPrank(user);
        token.approve(address(manager), depositAmount);
        vm.expectEmit(true, true, true, true);
        emit IYieldStrategyManager.DepositedIntoStrategy(user, address(strategy), tokens, amounts, "", user);
        manager.deposit(address(strategy), tokens, amounts, "", user);
        vm.stopPrank();
    }

    function test_withdrawingFromStrategyFailsForNonWhitelistedStrategy() external {
        address nonWhitelistedStrategy = makeAddr("non whitelisted strategy");

        address[] memory tokens = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategyManager.YieldStrategyManager__NotWhitelistedStrategy.selector, nonWhitelistedStrategy
            )
        );
        manager.withdraw(user, nonWhitelistedStrategy, tokens, amounts, "", user);
    }

    function test_withdrawingFromStrategyFailsForArrayLengthMismatch() external {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](0);

        tokens[0] = address(token);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Utils.Utils__LengthsDoNotMatch.selector, 1, 0));
        manager.withdraw(user, address(strategy), tokens, amounts, "", user);
    }

    function test_withdrawingFromStrategyFailsIfToIsAddressZero() external {
        address[] memory tokens = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.prank(user);
        vm.expectRevert(Utils.Utils__AddressZero.selector);
        manager.withdraw(user, address(strategy), tokens, amounts, "", address(0));
    }

    function test_withdrawingFromStrategyFailsIfCallerIsNotPositionHolderOrApprovedOperator() external {
        address randomUser = makeAddr("random address");

        address[] memory tokens = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.prank(randomUser);
        vm.expectRevert(IYieldStrategyManager.YieldStrategyManager__NotUserOrOperator.selector);
        manager.withdraw(user, address(strategy), tokens, amounts, "", randomUser);
    }

    function test_withdrawingFromStrategySucceeds() external {
        uint256 depositAmount = 100e18;

        _depositIntoMockStrategy(depositAmount);

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(token);
        amounts[0] = depositAmount;

        vm.prank(user);
        manager.withdraw(user, address(strategy), tokens, amounts, "", user);

        assertEq(token.balanceOf(user), depositAmount);
    }

    function test_withdrawingFromStrategyEmitsEvent() external {
        uint256 depositAmount = 100e18;

        _depositIntoMockStrategy(depositAmount);

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(token);
        amounts[0] = depositAmount;

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit IYieldStrategyManager.WithdrawnFromStrategy(user, address(strategy), tokens, amounts, "", user);
        manager.withdraw(user, address(strategy), tokens, amounts, "", user);
    }

    function test_withdrawingFromStrategySucceedsIfCallerIsApprovedOperator() external {
        uint256 depositAmount = 100e18;
        address operator = makeAddr("operator");

        _addOperator(address(strategy), operator);

        _depositIntoMockStrategy(depositAmount);

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(token);
        amounts[0] = depositAmount;

        vm.prank(operator);
        manager.withdraw(user, address(strategy), tokens, amounts, "", operator);

        assertEq(token.balanceOf(operator), depositAmount);
    }

    function _addOperator(address _strategy, address _operator) internal {
        vm.prank(user);
        manager.setOperator(_strategy, _operator, true);
    }

    function _depositIntoMockStrategy(uint256 _amount) internal {
        deal(address(token), user, _amount);

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(token);
        amounts[0] = _amount;

        vm.startPrank(user);
        token.approve(address(manager), _amount);
        manager.deposit(address(strategy), tokens, amounts, "", user);
        vm.stopPrank();
    }
}
