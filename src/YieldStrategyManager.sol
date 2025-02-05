// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/utils/structs/EnumerableSet.sol";

import { IStrategy } from "./interfaces/IStrategy.sol";
import { IYieldStrategyManager } from "./interfaces/IYieldStrategyManager.sol";

contract YieldStrategyManager is Ownable, IYieldStrategyManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    EnumerableSet.AddressSet private s_whitelistedStrategies;
    mapping(address user => mapping(address strategy => mapping(address token => uint256 amount))) private s_positions;

    constructor(address _owner) Ownable(_owner) { }

    function whitelistStrategy(address _strategy) external onlyOwner {
        _requireNotAddressZero(_strategy);

        s_whitelistedStrategies.add(_strategy);

        emit WhitelistedStrategy(_strategy);
    }

    function removeStrategy(address _strategy) external onlyOwner {
        _requireWhitelistedStrategy(_strategy);

        s_whitelistedStrategies.remove(_strategy);

        emit RemovedStrategyFromWhitelist(_strategy);
    }

    function deposit(
        address _strategy,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _for
    )
        external
    {
        uint256 length = _tokens.length;

        _requireWhitelistedStrategy(_strategy);
        _requireArrayLengthsMatch(length, _amounts.length);
        _requireNotAddressZero(_for);
        _validateAndManageInputTokenAmounts(_strategy, _tokens, _amounts);

        for (uint256 i; i < length; ++i) {
            s_positions[_for][_strategy][_tokens[i]] += _amounts[i];
        }

        bool success = IStrategy(_strategy).deposit(_tokens, _amounts, _additionalData);
        if (!success) {
            revert YieldStrategyManager__FailedToDepositIntoStrategy();
        }

        emit DepositedIntoStrategy(msg.sender, _strategy, _tokens, _amounts, _additionalData, _for);
    }

    function withdraw(
        address _strategy,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes calldata _additionalData,
        address _to
    )
        external
    {
        uint256 length = _tokens.length;

        _requireWhitelistedStrategy(_strategy);
        _requireArrayLengthsMatch(length, _amounts.length);
        _requireNotAddressZero(_to);

        for (uint256 i; i < length; ++i) {
            s_positions[msg.sender][_strategy][_tokens[i]] -= _amounts[i];
        }

        bool success = IStrategy(_strategy).withdraw(_tokens, _amounts, _additionalData, _to);
        if (!success) {
            revert YieldStrategyManager__FailedToWithdrawFromStrategy();
        }

        emit WithdrawnFromStrategy(msg.sender, _strategy, _tokens, _amounts, _additionalData, _to);
    }

    function _requireArrayLengthsMatch(uint256 _length1, uint256 _length2) internal pure {
        if (_length1 != _length2) revert YieldStrategyManager__ArrayLengthMismatch();
    }

    function _validateAndManageInputTokenAmounts(
        address _strategy,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    )
        internal
    {
        uint256 length = _tokens.length;
        if (length != _amounts.length) revert YieldStrategyManager__ArrayLengthMismatch();

        for (uint256 i; i < length; ++i) {
            _requireNotAddressZero(_tokens[i]);
            _requireNotValueZero(_amounts[i]);

            IERC20(_tokens[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
            IERC20(_tokens[i]).approve(_strategy, _amounts[i]);
        }
    }

    function _requireNotAddressZero(address _address) internal pure {
        if (_address == address(0)) revert YieldStrategyManager__AddressZero();
    }

    function _requireNotValueZero(uint256 _value) internal pure {
        if (_value == 0) revert YieldStrategyManager__ValueZero();
    }

    function _requireWhitelistedStrategy(address _strategy) internal view {
        if (!s_whitelistedStrategies.contains(_strategy)) {
            revert YieldStrategyManager__NotWhitelistedStrategy(_strategy);
        }
    }

    function getStrategy(uint256 _index) external view returns (address) {
        return s_whitelistedStrategies.at(_index);
    }

    function getAllStrategies() external view returns (address[] memory) {
        return s_whitelistedStrategies.values();
    }

    function getPosition(address _user, address _strategy, address _token) external view returns (uint256) {
        return s_positions[_user][_strategy][_token];
    }
}
