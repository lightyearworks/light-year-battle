// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library Coordinate {

    uint256 constant C_00 = 36 * 26 * 36 * 26 * 36;
    uint256 constant C_01 = 26 * 36 * 26 * 36;
    uint256 constant C_02 = 36 * 26 * 36;
    uint256 constant C_03 = 26 * 36;
    uint256 constant C_04 = 36;

    function coordinateStringToUserId(string memory coordinateString) public pure returns (uint256){
        bytes memory b = bytes(coordinateString);
        uint256 result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint8 byteInt = uint8(b[i]);
            uint256 number = getNumberFromByteInt(i, byteInt);
            if (i == 0) {
                result += number * C_00;
            } else if (i == 1) {
                result += number * C_01;
            } else if (i == 2) {
                result += number * C_02;
            } else if (i == 3) {
                result += number * C_03;
            } else if (i == 4) {
                result += number * C_04;
            } else if (i == 5) {
                result += number;
            }
        }
        return result;
    }

    function userIdToCoordinateString(uint256 userId) public pure returns (string memory){
        byte b0 = byte(uint8(getByteIntFromNumber(0, div(userId, C_00))));
        userId -= div(userId, C_00) * C_00;

        byte b1 = byte(uint8(getByteIntFromNumber(1, div(userId, C_01))));
        userId -= div(userId, C_01) * C_01;

        byte b2 = byte(uint8(getByteIntFromNumber(2, div(userId, C_02))));
        userId -= div(userId, C_02) * C_02;

        byte b3 = byte(uint8(getByteIntFromNumber(3, div(userId, C_03))));
        userId -= div(userId, C_03) * C_03;

        byte b4 = byte(uint8(getByteIntFromNumber(4, div(userId, C_04))));
        userId -= div(userId, C_04) * C_04;

        byte b5 = byte(uint8(getByteIntFromNumber(5, userId)));

        bytes memory myBytes = abi.encodePacked(b0, b1, b2, b3, b4, b5);
        string memory s = string(myBytes);
        return s;
    }

    function getByteIntFromNumber(uint256 index, uint256 number) public pure returns (uint256) {
        if (index % 2 == 0) {
            return number + 65;
        } else {
            if (number >= 0 && number <= 9) {
                return number + 48;
            } else if (number >= 10 && number <= 36) {
                return number - 10 + 65;
            }
        }
        revert();
    }

    function getNumberFromByteInt(uint256 index, uint8 byteInt) public pure returns (uint256) {
        if (index % 2 == 0) {
            return byteInt - 65;
        } else {
            if (byteInt >= 48 && byteInt <= 57) {
                return byteInt - 48;
            } else if (byteInt >= 65 && byteInt <= 90) {
                return byteInt - 65 + 10;
            }
        }
        revert();
    }

    function div(uint256 a, uint256 b) public pure returns (uint256){
        return a / b;
    }
}