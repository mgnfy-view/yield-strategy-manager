// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IStrategy {
    function deposit(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _for
    )
        external
        returns (bool);
    function withdraw(
        address _by,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _to
    )
        external
        returns (bool);
    function getYieldStrategyManager() external view returns (address);
}
