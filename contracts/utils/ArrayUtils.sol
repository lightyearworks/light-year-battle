// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library ArrayUtils {

    /**
     *
     */
    function contains(uint32[]memory arr, uint32 v) public pure returns (bool){
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == v) {
                return true;
            }
        }
        return false;
    }

    /**
     * 
     */
    function indexOf(uint32[] memory arr, uint32 item) public pure returns (bool, uint256){
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == item) {
                return (true, i);
            }
        }
        return (false, 0);
    }
}