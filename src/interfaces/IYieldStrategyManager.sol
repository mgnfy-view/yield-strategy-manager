// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IYieldStrategyManager {
    event WhitelistedStrategy(address indexed strategy);
    event RemovedStrategyFromWhitelist(address indexed strategy);
    event DepositedIntoStrategy(
        address by,
        address indexed strategy,
        address[] indexed tokens,
        uint256[] amounts,
        bytes additionalData,
        address indexed onBehalfOf
    );
    event WithdrawnFromStrategy(
        address indexed by,
        address indexed strategy,
        address[] indexed tokens,
        uint256[] amounts,
        bytes additionalData,
        address to
    );

    error YieldStrategyManager__FailedToDepositIntoStrategy();
    error YieldStrategyManager__FailedToWithdrawFromStrategy();
    error YieldStrategyManager__NotWhitelistedStrategy(address strategy);

    function whitelistStrategy(address _strategy) external;
    function deposit(
        address _strategy,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _onBehalfOf
    )
        external;
    function withdraw(
        address _strategy,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _to
    )
        external;
    function getStrategy(uint256 _index) external view returns (address);
    function getAllStrategies() external view returns (address[] memory);
}
