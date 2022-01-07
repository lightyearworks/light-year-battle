// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IHeroAttrConfig.sol";
import "../interface/IRegistry.sol";
import "../interface/IHero.sol";

contract HeroAttrConfig is IHeroAttrConfig {

    address public registryAddress;

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function hero() private view returns (IHero){
        return IHero(registry().hero());
    }

    function getAttributesById(uint256 HeroId_) public view override returns (uint256[] memory){
        IHero.Info memory info = hero().heroInfo(HeroId_);
        return getAttributesByInfo(info);
    }

    function getAttributesByInfo(IHero.Info memory info_) public view override returns (uint256[] memory){
        uint16 level = info_.level;
        uint8 quality = info_.quality;
        uint8 heroType = info_.heroType;
        uint256 rarity = getHeroRarity(heroType);
        // attributes
        uint256 strength = rarity * 10;
        uint256 dexterity = rarity * 10;
        uint256 intelligence = rarity * 10;
        uint256 luck = rarity * 10;

        uint256[] memory attrs = new uint256[](8);
        attrs[0] = level;
        attrs[1] = quality;
        attrs[2] = heroType;
        attrs[3] = rarity;
        // attributes
        attrs[4] = strength;
        attrs[5] = dexterity;
        attrs[6] = intelligence;
        attrs[7] = luck;
        return attrs;
    }

    function getHeroRarity(uint256 heroType_) public pure returns (uint256){
        if (heroType_ < 12) {
            return 1;
        } else if (heroType_ < 24) {
            return 2;
        } else if (heroType_ < 36) {
            return 3;
        } else {
            return 4;
        }
    }
}