// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "@forge/Script.sol";

import { MorphoBaseStrategy } from "../../src/strategies/MorphoBaseStrategy.sol";

contract DeployYieldStrategyManager is Script {
    address public constant yieldStrategyManager = 0x90Cae48cEC3595Cd1A6a9D806679EEE50F364979;
    address public constant morpho = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    MorphoBaseStrategy public morphoBaseStrategy;

    function run() public returns (address) {
        vm.startBroadcast();
        morphoBaseStrategy = new MorphoBaseStrategy(yieldStrategyManager, morpho);
        vm.stopBroadcast();

        return address(morphoBaseStrategy);
    }
}
