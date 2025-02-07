// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Strategy } from "../../src/Strategy.sol";

contract MockStrategy is Strategy {
    constructor(address _yieldStrategyManager) Strategy(_yieldStrategyManager) { }

    function deposit(
        address[] calldata, /* _tokens */
        uint256[] calldata, /* _amounts */
        bytes calldata, /* _additionalData */
        address /* _for */
    )
        external
        pure
        onlyYieldStrategyManager
        returns (bool)
    {
        return true;
    }

    function withdraw(
        address, /* _by */
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata, /* _additionalData */
        address _to
    )
        external
        onlyYieldStrategyManager
        returns (bool)
    {
        IERC20(_tokens[0]).transfer(_to, _amounts[0]);

        return true;
    }
}
