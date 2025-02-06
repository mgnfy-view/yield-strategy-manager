// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library Utils {
    error Utils__NotEaxctlyOne();
    error Utils__AddressZero();
    error Utils__ValueZero();
    error Utils__LengthsDoNotMatch(uint256 length1, uint256 length2);

    function requireExactlyOne(uint256 _length) internal pure {
        if (_length != 1) revert Utils__NotEaxctlyOne();
    }

    function requireNotAddressZero(address _address) internal pure {
        if (_address == address(0)) revert Utils__AddressZero();
    }

    function requireNotValueZero(uint256 _value) internal pure {
        if (_value == 0) revert Utils__ValueZero();
    }

    function requireLengthsMatch(uint256 _length1, uint256 _length2) internal pure {
        if (_length1 != _length2) revert Utils__LengthsDoNotMatch(_length1, _length2);
    }
}
