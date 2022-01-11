// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IExploreConfig.sol";
import "../interface/IRegistry.sol";
import "../interface/IHeroAttrConfig.sol";

contract ExploreConfig is IExploreConfig {

    address public registryAddress;

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function heroAttrConfig() private view returns (IHeroAttrConfig){
        return IHeroAttrConfig(registry().heroAttrConfig());
    }

    function getMayDropByLevel(uint256 level_) public override pure returns (uint256[] memory){
        uint256[] memory mayDrop = new uint256[](8);
        level_++;
        mayDrop[0] = level_ * 500;
        mayDrop[1] = level_ * 500;
        mayDrop[2] = level_ * 500;
        mayDrop[3] = level_ * 500;
        mayDrop[4] = mayDrop[0] + 200;
        mayDrop[5] = mayDrop[1] + 200;
        mayDrop[6] = mayDrop[2] + 200;
        mayDrop[7] = mayDrop[3] + 200;
        return mayDrop;
    }

    function getRealDropByLevel(uint256 level_, uint256[] memory heroIdArray_) public override view returns (uint256[] memory){
        uint256[] memory mayDrop = getMayDropByLevel(level_);
        uint256[] memory realDrop = new uint256[](8);
        realDrop[4] = (mayDrop[0] + _random(0, 200)) * 1e18;
        realDrop[5] = (mayDrop[1] + _random(1, 200)) * 1e18;
        realDrop[6] = (mayDrop[2] + _random(2, 200)) * 1e18;
        realDrop[7] = (mayDrop[3] + _random(3, 200)) * 1e18;

        //drop reward by hero luck
        realDrop[0] = heroLuckReward(realDrop[4], heroIdArray_);
        realDrop[1] = heroLuckReward(realDrop[5], heroIdArray_);
        realDrop[2] = heroLuckReward(realDrop[6], heroIdArray_);
        realDrop[3] = heroLuckReward(realDrop[7], heroIdArray_);

        return realDrop;
    }

    function pirateBattleShips(uint256 level_) public override pure returns (IBattle.BattleShip[] memory){
        IBattle.BattleShip[] memory ships = new IBattle.BattleShip[](4);
        uint32 health = 30 * uint32(level_ + 1);
        uint32 attack = 30 * uint32(level_ + 1);
        uint32 defense = 30 * uint32(level_ + 1);
        IBattle.BattleShip memory info = IBattle.BattleShip(health, attack, defense);
        ships[0] = info;
        ships[1] = info;
        ships[2] = info;
        ships[3] = info;
        return ships;
    }

    function heroLuckReward(uint256 drop_, uint256[] memory heroIdArray_) public view returns (uint256){
        uint256 boost = 100;
        for (uint i = 0; i < heroIdArray_.length; i++) {
            uint256 heroId = heroIdArray_[i];
            if (heroId != 0) {
                uint256 rarity = heroAttrConfig().getAttributesById(heroId)[3];
                if (rarity == 1) {
                    boost += 50;
                } else if (rarity == 2) {
                    boost += 100;
                } else if (rarity == 3) {
                    boost += 200;
                } else if (rarity == 4) {
                    boost += 400;
                }
            }
        }
        return drop_ * boost / 100;
    }

    function exploreDuration() public override pure returns (uint256){
        return 8 hours;
    }

    function _random(uint256 seed_, uint256 randomSize_) private view returns (uint256){
        uint256 difficulty = block.difficulty;
        uint256 gaslimit = block.gaslimit;
        uint256 number = block.number;
        uint256 timestamp = block.timestamp;
        uint256 gasprice = tx.gasprice;
        uint256 random = uint256(keccak256(abi.encodePacked(seed_, difficulty, gaslimit, number, timestamp, gasprice))) % randomSize_;
        return random;
    }
}