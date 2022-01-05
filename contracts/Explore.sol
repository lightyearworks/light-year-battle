// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IRegistry.sol";
import "./interface/IFleets.sol";
import "./interface/IAccount.sol";
import "./interface/IBattle.sol";
import "./interface/IShip.sol";
import "./interface/IExploreConfig.sol";
import "./interface/ICommodityERC20.sol";

contract Explore is Ownable {

    address public registryAddress;

    event ExploreResult(uint256 win, uint256[] resource, uint256 level, bytes battleBytes);

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function fleets() private view returns (IFleets){
        return IFleets(registry().fleets());
    }

    function account() private view returns (IAccount){
        return IAccount(registry().account());
    }

    function battle() private view returns (IBattle){
        return IBattle(registry().battle());
    }

    function ship() private view returns (IShip){
        return IShip(registry().ship());
    }

    function exploreConfig() private view returns (IExploreConfig){
        return IExploreConfig(registry().exploreConfig());
    }

    function _handleExploreResult(uint256 index_, uint8 win_, uint256 userMaxLevel_, uint256 level_, bytes memory battleBytes_) private {

        //explore lose
        if (win_ == 0) {
            emit ExploreResult(0, new uint256[](0), 0, battleBytes_);
            return;
        }

        //add user explore level
        if (userMaxLevel_ == level_) {
            account().addExploreLevel(_msgSender());
            userMaxLevel_++;
        }

        //win and get real drop
        uint256[] memory heroIdArray = fleets().userFleet(_msgSender(), index_).heroIdArray;
        uint256[] memory winResource = exploreConfig().getRealDropByLevel(level_, heroIdArray);
        _exploreDrop(winResource);
        emit ExploreResult(1, winResource, userMaxLevel_, battleBytes_);
    }

    function fleetBattleExplore(uint256 index_, uint256 level_) public {

        //check user explore time
        require(now >= account().userExploreTime(_msgSender()) + exploreConfig().exploreDuration(), "Explore not ready.");

        //get ship info array from fleet
        IFleets.Fleet memory fleet = fleets().userFleet(_msgSender(), index_);
        uint256 attackerLen = fleet.shipIdArray.length;
        IShip.Info[] memory attackerShips = new IShip.Info[](attackerLen);
        for (uint i = 0; i < attackerLen; i++) {
            attackerShips[i] = ship().shipInfo(fleet.shipIdArray[i]);
        }

        //get pirate ships
        IShip.Info[] memory defenderShips = exploreConfig().pirateShips(level_);

        //battle
        bytes memory battleBytes = battle().battleByShipInfo(attackerShips, defenderShips);
        uint8 win = uint8(battleBytes[0]);

        //handle explore result
        uint256 userMaxLevel = account().userExploreLevel(_msgSender());
        _handleExploreResult(index_, win, userMaxLevel, level_, battleBytes);

        //user explore time
        account().setUserExploreTime(_msgSender(), now);
    }

    function _exploreDrop(uint256[] memory winResource_) private {
        ICommodityERC20(registry().tokenIron()).mint(_msgSender(), winResource_[0]);
        ICommodityERC20(registry().tokenGold()).mint(_msgSender(), winResource_[1]);
        ICommodityERC20(registry().tokenSilicate()).mint(_msgSender(), winResource_[2]);
        ICommodityERC20(registry().tokenEnergy()).mint(_msgSender(), winResource_[3]);
    }

    uint256 private nonce;

    function _random(uint256 randomSize_) private returns (uint256){
        nonce++;
        uint256 difficulty = block.difficulty;
        uint256 gaslimit = block.gaslimit;
        uint256 number = block.number;
        uint256 timestamp = block.timestamp;
        uint256 gasprice = tx.gasprice;
        uint256 random = uint256(keccak256(abi.encodePacked(nonce, difficulty, gaslimit, number, timestamp, gasprice))) % randomSize_;
        return random;
    }
}