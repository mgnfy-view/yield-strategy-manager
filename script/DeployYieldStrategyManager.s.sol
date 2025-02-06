// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script } from "@forge/Script.sol";

import { YieldStrategyManager } from "../src/YieldStrategyManager.sol";

contract DeployYieldStrategyManager is Script {
    YieldStrategyManager public manager;

    function run() public returns (address) {
        vm.startBroadcast();
        manager = new YieldStrategyManager(msg.sender);
        vm.stopBroadcast();

        return address(manager);
    }
}
