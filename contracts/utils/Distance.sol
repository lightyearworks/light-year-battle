// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library Distance {

    function getTransportTime(string memory c0, string memory c1) public pure returns (uint256){
        uint256 distance = getDistance(c0, c1);
        uint256 second = distance / 100000;
        return second;
    }

    function getDistance(string memory c0, string memory c1) public pure returns (uint256){
        (uint256 x,uint256 y,uint256 z) = getCoordinate(c0);
        (uint256 a,uint256 b,uint256 c) = getCoordinate(c1);

        uint256 i0 = absoluteSub(x, a);
        uint256 i1 = absoluteSub(y, b);
        uint256 i2 = absoluteSub(z, c);

        uint256 d0 = i0 * i0;
        uint256 d1 = i1 * i1;
        uint256 d2 = i2 * i2;

        return d0 + d1 + d2;
    }

    function getCoordinate(string memory coordinate) public pure returns (uint256 x, uint256 y, uint256 z) {
        bytes32 r = keccak256(abi.encodePacked(coordinate));
        bytes2 a = bytes2(r);
        bytes2 b = bytes2(r << 16 * 1);
        bytes2 c = bytes2(r << 16 * 2);
        x = uint256(uint16(a));
        y = uint256(uint16(b));
        z = uint256(uint16(c));
    }

    function absoluteSub(uint256 a, uint256 b) public pure returns (uint256){
        if (a > b) {
            return a - b;
        } else {
            return b - a;
        }
    }

}