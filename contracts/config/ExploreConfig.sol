// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IExploreConfig.sol";
import "../interface/IRegistry.sol";
import "../interface/IHeroConfig.sol";

contract ExploreConfig is IExploreConfig {

    address public registryAddress;

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function heroConfig() private view returns (IHeroConfig){
        return IHeroConfig(registry().heroConfig());
    }

    function getMayDropByLevel(uint256 level_) public override pure returns (uint256[] memory){
        uint256[] memory mayDrop = new uint256[](8);
        level_++;
        mayDrop[0] = level_ * 100;
        mayDrop[1] = level_ * 100;
        mayDrop[2] = level_ * 50;
        mayDrop[3] = level_ * 50;
        mayDrop[4] = mayDrop[0] + 100;
        mayDrop[5] = mayDrop[1] + 100;
        mayDrop[6] = mayDrop[2] + 100;
        mayDrop[7] = mayDrop[3] + 100;
        return mayDrop;
    }

    function getRealDropByLevel(uint256 level_, uint256[] memory heroIdArray_) public override view returns (uint256[] memory){
        uint256[] memory mayDrop = getMayDropByLevel(level_);
        uint256[] memory realDrop = new uint256[](8);
        realDrop[4] = (mayDrop[0] + _random(0, 100)) * 1e18;
        realDrop[5] = (mayDrop[1] + _random(1, 100)) * 1e18;
        realDrop[6] = (mayDrop[2] + _random(2, 100)) * 1e18;
        realDrop[7] = (mayDrop[3] + _random(3, 100)) * 1e18;

        //drop reward by hero luck
        realDrop[0] = heroLuckReward(realDrop[4], heroIdArray_);
        realDrop[1] = heroLuckReward(realDrop[5], heroIdArray_);
        realDrop[2] = heroLuckReward(realDrop[6], heroIdArray_);
        realDrop[3] = heroLuckReward(realDrop[7], heroIdArray_);

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

    function heroLuckReward(uint256 drop_, uint256[] memory heroIdArray_) public view returns (uint256){
        for (uint i = 0; i < heroIdArray_.length; i++) {
            uint256 heroId = heroIdArray_[i];
            if (heroId != 0) {
                uint256 luck = heroConfig().getAttributesById(heroId)[6];
                drop_ = drop_ * (100 + luck) / 100;
            }
        }
        return drop_;
    }

    function exploreDuration() public override pure returns (uint256){
        return 6 hours;
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