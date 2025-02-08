// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "@forge/Script.sol";

import { YieldStrategyManager } from "../src/YieldStrategyManager.sol";

contract DeployYieldStrategyManager is Script {
    YieldStrategyManager public manager;

    function run() public returns (address) {
        vm.startBroadcast();
        manager = new YieldStrategyManager(0xd9c5ee55812e5e1c6035b52887CCE46915156E4E);
        vm.stopBroadcast();

        return address(manager);
    }
}
