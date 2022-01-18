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
        uint256 health = getAttack(level, quality, shipType) * 2;
        uint256 attack = getAttack(level, quality, shipType);
        uint256 defense = getAttack(level, quality, shipType);

        uint256[] memory attrs = new uint256[](7);
        attrs[0] = level;
        attrs[1] = quality;
        attrs[2] = shipType;
        attrs[3] = category;
        // attributes
        attrs[4] = health;
        attrs[5] = attack;
        attrs[6] = defense;
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

    function getAttack(uint256 level_, uint256 quality_, uint256 shipType_) public pure returns (uint256){
        uint256 basic = 50 + quality_;
        basic = basic * (level_ + 1) * 150 / 100;
        if (shipType_ == 6) {
            return basic * 1;
        } else if (shipType_ == 8) {
            return basic * 4;
        } else if (shipType_ == 12) {
            return basic * 10;
        } else if (shipType_ == 15) {
            return basic * 20;
        } else if (shipType_ == 2) {
            return basic * 40;
        } else if (shipType_ == 3) {
            return basic * 50;
        } else if (shipType_ == 7) {
            return basic * 60;
        } else if (shipType_ == 9) {
            return basic * 100;
        } else if (shipType_ == 10) {
            return basic * 110;
        } else if (shipType_ == 13) {
            return basic * 120;
        } else if (shipType_ == 16) {
            return basic * 200;
        } else if (shipType_ == 17) {
            return basic * 240;
        } else if (shipType_ == 18) {
            return basic * 300;
        } else if (shipType_ == 19) {
            return basic * 1000;
        }
    }
}