// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { IYieldStrategyManager } from "../../../../src/interfaces/IYieldStrategyManager.sol";

import { Utils } from "../../../../src/Utils.sol";
import { YieldStrategyManager } from "../../../../src/YieldStrategyManager.sol";
import { Id } from "../../../../src/interfaces/vendors/morpho/IMorpho.sol";
import { MorphoBaseStrategy } from "../../../../src/strategies/MorphoBaseStrategy.sol";
import { TestBase } from "../../../utils/TestBase.sol";

contract MorphoBaseStrategyTest is TestBase {
    uint256 public BASE_MAINNET_CHAIN_ID = 8453;

    address public usdc;
    address public morpho;
    MorphoBaseStrategy public morphoBaseStrategy;

    Id public ezETHUSDCMarketId;

    function setUp() public override {
        if (block.chainid != BASE_MAINNET_CHAIN_ID) revert TestBase__UnsupportedChain();

        super.setUp();

        usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        morpho = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
        morphoBaseStrategy = new MorphoBaseStrategy(address(manager), morpho);

        ezETHUSDCMarketId = Id.wrap(0xf24417ee06adc0b0836cf0dbec3ba56c1059f62f53a55990a38356d42fa75fa2);

        _addStrategy(address(morphoBaseStrategy));
    }

    function test_checkInitialization() external view {
        assertEq(morphoBaseStrategy.getMorpho(), morpho);
        assertEq(morphoBaseStrategy.getYieldStrategyManager(), address(manager));
    }

    function test_depositIntoMorphoBaseStrategy() external {
        uint256 depositAmount = 100e6;

        _depositIntoMorphoBaseStrategy(usdc, ezETHUSDCMarketId, depositAmount);

        uint256 sharesReceived = morphoBaseStrategy.getMarketSharesForUser(user, ezETHUSDCMarketId);

        assertGt(sharesReceived, 0);
    }

    function test_withdrawFromMorphoBaseStrategy() external {
        uint256 depositAmount = 100e6;
        uint256 oneUsdc = 1e6;

        _depositIntoMorphoBaseStrategy(usdc, ezETHUSDCMarketId, depositAmount);
        uint256 sharesReceived = morphoBaseStrategy.getMarketSharesForUser(user, ezETHUSDCMarketId);

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = usdc;
        amounts[0] = sharesReceived;

        vm.startPrank(user);
        manager.withdraw(
            user, address(morphoBaseStrategy), tokens, amounts, abi.encode(ezETHUSDCMarketId, sharesReceived), user
        );
        vm.stopPrank();

        uint256 shareBalance = morphoBaseStrategy.getMarketSharesForUser(user, ezETHUSDCMarketId);

        assertEq(shareBalance, 0);
        // Accounting for precision loss while rounding
        assertGt(IERC20(usdc).balanceOf(user), depositAmount - oneUsdc);
    }

    function _depositIntoMorphoBaseStrategy(address _token, Id _marketId, uint256 _amount) internal {
        deal(_token, user, _amount);

        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = _token;
        amounts[0] = _amount;

        vm.startPrank(user);
        IERC20(_token).approve(address(manager), _amount);
        manager.deposit(address(morphoBaseStrategy), tokens, amounts, abi.encode(_marketId), user);
        vm.stopPrank();
    }
}
