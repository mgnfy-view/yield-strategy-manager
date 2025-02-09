// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { IYieldStrategyManager } from "../../../../src/interfaces/IYieldStrategyManager.sol";
import { IPool } from "../../../../src/interfaces/vendors/aaveV3/IPool.sol";

import { Utils } from "../../../../src/Utils.sol";
import { YieldStrategyManager } from "../../../../src/YieldStrategyManager.sol";
import { AaveV3BaseStrategy } from "../../../../src/strategies/AaveV3BaseStrategy.sol";
import { TestBase } from "../../../utils/TestBase.sol";

contract AaveV3BaseStrategyTest is TestBase {
    uint256 public BASE_MAINNET_CHAIN_ID = 8453;

    address public usdc;
    address public pool;
    AaveV3BaseStrategy public aaveV3BaseStrategy;

    function setUp() public override {
        if (block.chainid != BASE_MAINNET_CHAIN_ID) revert TestBase__UnsupportedChain();

        super.setUp();

        usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        pool = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
        aaveV3BaseStrategy = new AaveV3BaseStrategy(address(manager), pool);

        _addStrategy(address(aaveV3BaseStrategy));
    }

    function test_checkInitialization() external view {
        assertEq(aaveV3BaseStrategy.getYieldStrategyManager(), address(manager));
        assertEq(aaveV3BaseStrategy.getPool(), pool);
    }

    function test_depositingIntoAaveV3BaseStrategySucceeds() external {
        uint256 depositAmount = 100e6;

        _depositIntoAaveV3BaseStrategy(usdc, depositAmount);

        address aUSDC = IPool(pool).getReserveData(usdc).aTokenAddress;
        uint256 userATokenBalance = aaveV3BaseStrategy.getATokenBalance(user, usdc);

        assertGt(IERC20(aUSDC).balanceOf(address(aaveV3BaseStrategy)), 0);
        assertGt(userATokenBalance, 0);
    }

    function test_withdrawingFromAaveV3BaseStrategySucceeds() external {
        uint256 depositAmount = 100e6;

        _depositIntoAaveV3BaseStrategy(usdc, depositAmount);

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = usdc;
        amounts[0] = depositAmount;

        vm.prank(user);
        manager.withdraw(user, address(aaveV3BaseStrategy), tokens, amounts, "", user);

        address aUSDC = IPool(pool).getReserveData(usdc).aTokenAddress;
        uint256 userATokenBalance = aaveV3BaseStrategy.getATokenBalance(user, aUSDC);

        assertEq(IERC20(aUSDC).balanceOf(address(aaveV3BaseStrategy)), 0);
        assertEq(userATokenBalance, 0);
    }

    function _depositIntoAaveV3BaseStrategy(address _token, uint256 _amount) internal {
        deal(_token, user, _amount);

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = _token;
        amounts[0] = _amount;

        vm.startPrank(user);
        IERC20(_token).approve(address(manager), _amount);
        manager.deposit(address(aaveV3BaseStrategy), tokens, amounts, abi.encode(0), user);
        vm.stopPrank();
    }
}
