// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IFleetsConfig.sol";
import "../interface/IRegistry.sol";
import "../interface/IFleets.sol";
import "../interface/IShip.sol";
import "../interface/IShipConfig.sol";

contract FleetsConfig is IFleetsConfig {

    address public registryAddress;

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function fleets() private view returns (IFleets){
        return IFleets(registry().fleets());
    }

    function ship() private view returns(IShip){
        return IShip(registry().ship());
    }

    function shipConfig() private view returns(IShipConfig){
        return IShipConfig(registry().shipConfig());
    }

    mapping(uint256 => uint256[]) private configMap;

    function setConfig(uint256 key, uint256[] memory value) public {
        configMap[key] = value;
    }

    function getConfig(uint256 key) public override returns (uint256[] memory){
        return configMap[key];
    }

    function getUserFleetLimit() public override pure returns (uint256){
        return 5;
    }

    function getFleetShipLimit() public override pure returns (uint256){
        return 4;
    }

    function getGoHomeDuration(address, uint256) public override pure returns (uint256){
        return 3600;
    }
    
    function getGoMarketDuration(address, uint256) public override pure returns (uint256){
        return 3600;
    }

    function getFleetFormationConfig() public override pure returns (uint256[] memory){
        uint256[] memory config=new uint256[](4);
        uint256 shipLimit=8;
        uint256 battleLimit=4;
        uint256 minerLimit=2;
        uint256 cargoLimit=2;
        config[0]=shipLimit;
        config[1]=battleLimit;
        config[2]=minerLimit;
        config[3]=cargoLimit;
        return config;
    }

    function checkFleetFormationConfig(uint256[] memory shipIdArray_) public override view returns(bool){
        uint256[] memory count=new uint256[](4);
        for(uint i=0;i<shipIdArray_.length;i++){
            uint256 category=shipConfig().getShipCategoryById(shipIdArray_[i]);
            count[category]++;
        }

        //check
        uint256[] memory config=getFleetFormationConfig();
        require(shipIdArray_.length<=config[0], "checkFleetFormationConfig: exceeds ship limit.");
        require(count[0]+count[3]<=config[1], "checkFleetFormationConfig: exceeds battle ship limit.");
        require(count[1]<=config[2], "checkFleetFormationConfig: exceeds miner ship limit.");
        require(count[2]<=config[3], "checkFleetFormationConfig: exceeds cargo ship limit.");
        return true;
    }

    function fleetTotalAttack(address addr_, uint256 index_) public override view returns(uint256){
        IFleets.Fleet memory fleet = fleets().userFleet(addr_,index_);
        uint256[] memory shipIdArray = fleet.shipIdArray;
        uint256 totalAttack=0;
        for(uint i=0; i<shipIdArray.length; i++){
            uint256 attack = shipConfig().getShipAttackById(shipIdArray[i]);
            totalAttack+=attack;
        }
        return totalAttack;
    }

    function allFleetsAttack(address addr_) public override view returns(uint256){
        IFleets.Fleet[] memory fleetArray = fleets().userFleets(addr_);
        uint256 totalAttack=0;
        for(uint i=0; i<fleetArray.length; i++){
            uint256 attack=fleetTotalAttack(addr_,i);
            totalAttack+=attack;
        }
        return totalAttack;
    }

    function fleetsAttackArray(address addr_) public override view returns(uint256[] memory){
        IFleets.Fleet[] memory fleetArray = fleets().userFleets(addr_);
        uint256[] memory attackArray = new uint256[](fleetArray.length);
        for(uint i=0; i<fleetArray.length; i++){
            uint256 attack=fleetTotalAttack(addr_,i);
            attackArray[i]=attack;
        }
        return attackArray;
    }
}