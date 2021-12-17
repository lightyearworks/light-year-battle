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

    function _handleExploreResult(uint8 win_, uint256 nowLevel_, uint256 level_, bytes memory battleBytes_) private {
        if (win_ == 1) {
            emit ExploreResult(1, new uint256[](0), 0, battleBytes_);
            return;
        }

        if (nowLevel_ == level_) {
            account().addExploreLevel(_msgSender());
        }

        uint256[] memory winResource = exploreConfig().getRealDropByLevel(level_);
        nowLevel_ = account().userExploreLevel(_msgSender());
        emit ExploreResult(2, winResource, nowLevel_, battleBytes_);
    }

    function fleetBattleExplore(uint256 index_, uint256 level_) public {
        IFleets.Fleet memory fleet = fleets().userFleet(_msgSender(), index_);
        uint256 attackerLen = fleet.shipIdArray.length;
        IShip.Info[] memory attackerShips = new IShip.Info[](attackerLen);
        for (uint i = 0; i < attackerLen; i++) {
            attackerShips[i] = ship().shipInfo(fleet.shipIdArray[i]);
        }

        IShip.Info[] memory defenderShips = exploreConfig().pirateShips(level_);

        //battle
        bytes memory battleBytes = battle().battleByShipInfo(attackerShips, defenderShips);
        uint8 win = uint8(battleBytes[0]);

        uint256 nowLevel = account().userExploreLevel(_msgSender());
        _handleExploreResult(win, nowLevel, level_, battleBytes);
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