// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/utils/structs/EnumerableSet.sol";

import { IStrategy } from "./interfaces/IStrategy.sol";
import { IYieldStrategyManager } from "./interfaces/IYieldStrategyManager.sol";

import { Utils } from "./Utils.sol";

/// @title YieldStrategyManager.
/// @author mgnfy-view.
/// @notice A yield strategy manager to be used by AI agents to maximize yield by allocating funds
/// accross strategies.
contract YieldStrategyManager is Ownable, IYieldStrategyManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @dev A set of whitelisted strategies by the owner.
    EnumerableSet.AddressSet private s_whitelistedStrategies;
    /// @dev The operators approved to manage positions on strategies on behalf of a user.
    mapping(address user => mapping(address strategy => address operator)) private s_operators;

    /// @notice Initializes the owner address.
    /// @param _owner The initial owner.
    constructor(address _owner) Ownable(_owner) { }

    /// @notice Owner only function to whitelist trusted strategies.
    /// @param _strategy The address of the strategy implementation contract.
    function whitelistStrategy(address _strategy) external onlyOwner {
        Utils.requireNotAddressZero(_strategy);

        s_whitelistedStrategies.add(_strategy);

        emit WhitelistedStrategy(_strategy);
    }

    /// @notice Owner only function to remove whitelisted strategies.
    /// @param _strategy The address of the strategy implementation contract.
    function removeStrategy(address _strategy) external onlyOwner {
        _requireWhitelistedStrategy(_strategy);

        s_whitelistedStrategies.remove(_strategy);

        emit RemovedStrategyFromWhitelist(_strategy);
    }

    /// @notice Users can approve their trusted operators to manage positions on various strategies
    /// on their behalf.
    /// @param _strategy The address of the strategy implementation contract.
    /// @param _operator The operator address.
    /// @param _setOperator To add or remove an operator.
    function setOperator(address _strategy, address _operator, bool _setOperator) external {
        _requireWhitelistedStrategy(_strategy);
        if (_setOperator) Utils.requireNotAddressZero(_operator);

        if (_setOperator) s_operators[msg.sender][_strategy] = _operator;
        else delete s_operators[msg.sender][_strategy];

        emit OperatorSet(msg.sender, _strategy, _operator, _setOperator);
    }

    /// @notice Enables any user to create a position in any of the whitelisted strategies.
    /// @dev Only basic sanity checks are performed here. More checks and validation is performed
    /// by the strategy itself.
    /// @param _strategy The address of the strategy implementation contract.
    /// @param _tokens A set of tokens to supply to the strategy.
    /// @param _amounts The token amounts to provide to the strategy.
    /// @param _additionalData Any additional strategy-specific data.
    /// @param _for The user to open the strategy on behalf of.
    function deposit(
        address _strategy,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _for
    )
        external
    {
        _requireWhitelistedStrategy(_strategy);
        Utils.requireLengthsMatch(_tokens.length, _amounts.length);
        Utils.requireNotAddressZero(_for);
        _validateAndManageInputTokenAmounts(_strategy, _tokens, _amounts);

        bool success = IStrategy(_strategy).deposit(_tokens, _amounts, _additionalData, _for);
        if (!success) {
            revert YieldStrategyManager__FailedToDepositIntoStrategy();
        }

        emit DepositedIntoStrategy(msg.sender, _strategy, _tokens, _amounts, _additionalData, _for);
    }

    /// @notice Enables a user with a valid position to withdraw from any a strategies.
    /// @dev An approved operator can withdraw on behalf of a user.
    /// @param _user The user address.
    /// @param _strategy The address of the strategy implementation contract.
    /// @param _tokens A set of tokens to withdraw from the strategy.
    /// @param _amounts The token amounts to provide to the strategy.
    /// @param _additionalData Any additional strategy-specific data.
    /// @param _to The address to direct the withdrawn tokens to.
    function withdraw(
        address _user,
        address _strategy,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _to
    )
        external
    {
        _requireWhitelistedStrategy(_strategy);
        Utils.requireLengthsMatch(_tokens.length, _amounts.length);
        Utils.requireNotAddressZero(_to);
        _requireUserOrOperator(_strategy, _user);

        bool success = IStrategy(_strategy).withdraw(_user, _tokens, _amounts, _additionalData, _to);
        if (!success) {
            revert YieldStrategyManager__FailedToWithdrawFromStrategy();
        }

        emit WithdrawnFromStrategy(_user, _strategy, _tokens, _amounts, _additionalData, _to);
    }

    /// @notice Reverts if the given strategy is not whitelisted.
    /// @param _strategy The address of the strategy implementation contract.
    function _requireWhitelistedStrategy(address _strategy) internal view {
        if (!s_whitelistedStrategies.contains(_strategy)) {
            revert YieldStrategyManager__NotWhitelistedStrategy(_strategy);
        }
    }

    /// @notice Performs sanity checks on the tokens and amounts passed, and transfers them to the strategy.
    /// @param _strategy The address of the strategy implementation contract.
    /// @param _tokens A set of tokens to supply to the strategy.
    /// @param _amounts The token amounts to provide to the strategy.
    function _validateAndManageInputTokenAmounts(
        address _strategy,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    )
        internal
    {
        uint256 length = _tokens.length;

        for (uint256 i; i < length; ++i) {
            Utils.requireNotAddressZero(_tokens[i]);
            Utils.requireNotValueZero(_amounts[i]);

            IERC20(_tokens[i]).safeTransferFrom(msg.sender, _strategy, _amounts[i]);
        }
    }

    /// @notice Reverts if the caller is not the user itself or an approved operator.
    /// @param _strategy The address of the strategy implementation contract.
    /// @param _user The user address.
    function _requireUserOrOperator(address _strategy, address _user) internal view {
        if (msg.sender != _user && s_operators[_user][_strategy] != msg.sender) {
            revert YieldStrategyManager__NotUserOrOperator();
        }
    }

    /// @notice Gets the strategy at a specifc index.
    /// @param _index The index number.
    function getStrategy(uint256 _index) external view returns (address) {
        return s_whitelistedStrategies.at(_index);
    }

    /// @notice Gets an array of all whitelisted strategies.
    function getAllStrategies() external view returns (address[] memory) {
        return s_whitelistedStrategies.values();
    }

    /// @notice Gets the operator address for a given user and strategy.
    /// @param _strategy The address of the strategy implementation contract.
    /// @param _user The user address.
    function getOperator(address _strategy, address _user) external view returns (address) {
        return s_operators[_user][_strategy];
    }
}
