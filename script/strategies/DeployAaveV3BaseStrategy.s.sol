// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "@forge/Script.sol";

import { AaveV3BaseStrategy } from "../../src/strategies/AaveV3BaseStrategy.sol";

contract DeployYieldStrategyManager is Script {
    address public constant yieldStrategyManager = 0x90Cae48cEC3595Cd1A6a9D806679EEE50F364979;
    address public constant pool = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
    AaveV3BaseStrategy public morphoBaseStrategy;

    function run() public returns (address) {
        vm.startBroadcast();
        morphoBaseStrategy = new AaveV3BaseStrategy(yieldStrategyManager, pool);
        vm.stopBroadcast();

        return address(morphoBaseStrategy);
    }
}
