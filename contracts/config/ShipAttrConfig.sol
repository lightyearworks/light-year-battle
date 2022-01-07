// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IShipAttrConfig.sol";
import "../interface/IRegistry.sol";

contract ShipAttrConfig is IShipAttrConfig {

    address public registryAddress;

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function ship() private view returns (IShip){
        return IShip(registry().ship());
    }

    function getAttributesById(uint256 shipId_) public view override returns (uint256[] memory){
        IShip.Info memory info = ship().shipInfo(shipId_);
        return getAttributesByInfo(info);
    }

    function getAttributesByInfo(IShip.Info memory info_) public view override returns (uint256[] memory){
        uint16 level = info_.level;
        uint8 quality = info_.quality;
        uint8 shipType = info_.shipType;
        uint256 category = getShipCategory(shipType);
        // attributes
        uint256 health = quality * 2;
        uint256 attack = quality + 50;
        uint256 defense = quality + 50;

        uint256[] memory attrs = new uint256[](7);
        attrs[0] = level;
        attrs[1] = quality;
        attrs[2] = shipType;
        attrs[3] = category;
        // attributes
        attrs[5] = health;
        attrs[6] = attack;
        attrs[7] = defense;
        return attrs;
    }

    function getShipCategory(uint8 shipType_) public override pure returns (uint256){
        if (shipType_ == 6 || shipType_ == 8 || shipType_ == 12 || shipType_ == 15) {
            return 0;
        } else if (shipType_ == 1 || shipType_ == 5) {
            return 1;
        } else if (shipType_ == 4 || shipType_ == 11 || shipType_ == 14) {
            return 2;
        } else {
            return 3;
        }
    }
}