// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Util.s
/// @author mgnfy-view.
/// @notice A basic library to perform sanity checks.
library Utils {
    error Utils__NotEaxctlyOne();
    error Utils__AddressZero();
    error Utils__ValueZero();
    error Utils__LengthsDoNotMatch(uint256 length1, uint256 length2);

    /// @notice Reverts if the passed value is exactly 1.
    /// @param _length The input value.
    function requireExactlyOne(uint256 _length) internal pure {
        if (_length != 1) revert Utils__NotEaxctlyOne();
    }

    /// @notice Reverts if the input address is address 0.
    /// @param _address The input address.
    function requireNotAddressZero(address _address) internal pure {
        if (_address == address(0)) revert Utils__AddressZero();
    }

    /// @notice Reverts if the input value is 0.
    /// @param _value The input value.
    function requireNotValueZero(uint256 _value) internal pure {
        if (_value == 0) revert Utils__ValueZero();
    }

    /// @notice Reverts if the input values are not the same.
    /// @param _length1 The first input value.
    /// @param _length2 The second input value.
    function requireLengthsMatch(uint256 _length1, uint256 _length2) internal pure {
        if (_length1 != _length2) revert Utils__LengthsDoNotMatch(_length1, _length2);
    }
}
