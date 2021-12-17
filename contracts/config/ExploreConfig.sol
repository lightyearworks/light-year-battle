// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IExploreConfig.sol";

contract ExploreConfig is IExploreConfig {

    function getMayDropByLevel(uint256 level_) public override pure returns (uint256[] memory){
        uint256[] memory mayDrop = new uint256[](6);
        mayDrop[0] = (level_ + 1) * 100;
        mayDrop[1] = mayDrop[0] + 50;
        mayDrop[2] = (level_ + 1) * 100;
        mayDrop[3] = mayDrop[2] + 50;
        mayDrop[4] = (level_ + 1) * 20;
        mayDrop[5] = mayDrop[4] + 20;
        return mayDrop;
    }

    function getRealDropByLevel(uint256 level_) public override view returns (uint256[] memory){
        uint256[] memory mayDrop = getMayDropByLevel(level_);
        uint256[] memory realDrop = new uint256[](3);
        realDrop[0]=mayDrop[0]+_random(50);
        realDrop[1]=mayDrop[2]+_random(50);
        realDrop[2]=mayDrop[4]+_random(20);
        return realDrop;
    }

    function pirateShips(uint256 level_) public override pure returns (IShip.Info[] memory){
        IShip.Info[] memory ships = new IShip.Info[](4);
        uint16 quality = uint16(level_ + 1) * 2;
        uint16 health = 100 + quality;
        IShip.Info memory info = IShip.Info(health, quality, 1, 1);
        ships[0] = info;
        ships[1] = info;
        ships[2] = info;
        ships[3] = info;
        return ships;
    }

    function _random(uint256 randomSize) private view returns (uint256){
        uint256 difficulty = block.difficulty;
        uint256 gaslimit = block.gaslimit;
        uint256 number = block.number;
        uint256 timestamp = block.timestamp;
        uint256 gasprice = tx.gasprice;
        uint256 random = uint256(keccak256(abi.encodePacked(difficulty, gaslimit, number, timestamp, gasprice))) % randomSize;
        return random;
    }
}