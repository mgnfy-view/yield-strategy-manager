// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IYieldStrategyManager {
    event WhitelistedStrategy(address indexed strategy);
    event RemovedStrategyFromWhitelist(address indexed strategy);
    event OperatorSet(address indexed user, address indexed strategy, address indexed operator, bool setOperator);
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
    error YieldStrategyManager__NotUserOrOperator();

    function whitelistStrategy(address _strategy) external;
    function setOperator(address _strategy, address _operator, bool _setOperator) external;
    function deposit(
        address _strategy,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _onBehalfOf
    )
        external;
    function withdraw(
        address _user,
        address _strategy,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _to
    )
        external;
    function getStrategy(uint256 _index) external view returns (address);
    function getAllStrategies() external view returns (address[] memory);
    function getOperator(address _strategy, address _user) external view returns (address);
}
