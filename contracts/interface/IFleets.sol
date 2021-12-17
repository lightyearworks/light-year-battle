// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

interface IFleets {

    //fleet status
    enum FleetStatus {Home, Guard, Market, GoBattle, Repair}

    //struct Fleet
    struct Fleet {
        FleetStatus status;
        address target;
        uint256 missionStartTime;
        uint256 missionEndTime;
        uint256[] shipIdArray;
        uint256[] heroIdArray;
        Asset asset;
    }

    //struct Asset
    struct Asset {
        uint256 iron;
        uint256 gold;
        uint256 silicate;
        uint256 energy;
    }

    function userFleet(address, uint256) external view returns (Fleet memory);

    function userFleets(address) external view returns (Fleet[] memory);

    function getGuardFleet(address addr_) external view returns (Fleet memory);

    function createFleet() external;

}
