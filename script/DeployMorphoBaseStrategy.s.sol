// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { MorphoBaseStrategy } from "../src/strategies/MorphoBaseStrategy.sol";
import { Script } from "@forge/Script.sol";

contract DeployYieldStrategyManager is Script {
    address public constant morpho = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    MorphoBaseStrategy public morphoBaseStrategy;

    function run() public returns (address) {
        vm.startBroadcast();
        morphoBaseStrategy = new MorphoBaseStrategy(morpho);
        vm.stopBroadcast();

        return address(morphoBaseStrategy);
    }
}
