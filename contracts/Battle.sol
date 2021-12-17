// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/BytesUtils.sol";
import "./interface/IBattle.sol";
import "./interface/IAccount.sol";
import "./interface/IRegistry.sol";
import "./interface/IFleets.sol";
import "./interface/IFleetsConfig.sol";
import "./interface/IShip.sol";
import "./interface/IShipConfig.sol";

contract Battle is IBattle {
    using BytesUtils for BytesUtils;

    address public registryAddress;

    event BattleResult(uint8 win, bytes battleBytes);

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function fleets() private view returns (IFleets){
        return IFleets(registry().fleets());
    }

    function fleetsConfig() private view returns (IFleetsConfig){
        return IFleetsConfig(registry().fleetsConfig());
    }

    function shipConfig() private view returns (IShipConfig){
        return IShipConfig(registry().shipConfig());
    }

    function account() private view returns (IAccount){
        return IAccount(registry().account());
    }

    function ship() private view returns (IShip){
        return IShip(registry().ship());
    }

    /**
     * battle
     */
    function battle(uint256 fleetIndex) external {

        //require fleet status
        IFleets.Fleet memory attackerFleet = fleets().userFleet(msg.sender, fleetIndex);
        require(attackerFleet.status == IFleets.FleetStatus.GoBattle, "battle: The fleet has not prepared for battle.");
        require(block.timestamp >= attackerFleet.missionEndTime, "battle: The fleet has not arrived yet.");

        //check defender fleet
        IFleets.Fleet memory defenderFleet = fleets().getGuardFleet(attackerFleet.target);

        //battle
        bytes memory battleBytes = _battle(attackerFleet, defenderFleet);
        account().saveBattleHistory(msg.sender, battleBytes);

        //handle battle result
        uint8 win = uint8(battleBytes[0]);

        //event
        emit BattleResult(win, battleBytes);
    }

    /**
     * private battle
     */
    function _battle(IFleets.Fleet memory attacker, IFleets.Fleet memory defender) private view returns (bytes memory){

        //ship length
        uint256 attackerLen = attacker.shipIdArray.length;
        uint256 defenderLen = defender.shipIdArray.length;

        //check length
        require(attackerLen > 0, "_battle: Attacker has no ship.");

        //attacker ships
        IShip.Info[] memory attackerShips = new IShip.Info[](attackerLen);
        for (uint i = 0; i < attackerLen; i++) {
            attackerShips[i] = ship().shipInfo(attacker.shipIdArray[i]);
        }

        //defender ships
        IShip.Info[] memory defenderShips = new IShip.Info[](defenderLen);
        for (uint i = 0; i < defenderLen; i++) {
            defenderShips[i] = ship().shipInfo(defender.shipIdArray[i]);
        }

        return battleByShipInfo(attackerShips, defenderShips);
    }

    function battleByShipInfo(IShip.Info[] memory attackerShips_, IShip.Info[] memory defenderShips_) public override view returns (bytes memory){

        //ship length
        uint256 attackerLen = attackerShips_.length;
        uint256 defenderLen = defenderShips_.length;

        //empty attacker
        if (attackerLen == 0) {
            attackerShips_ = new IShip.Info[](1);
            attackerShips_[0] = IShip.Info(0, 0, 0, 0);
        }

        //empty defender
        if (defenderLen == 0) {
            defenderShips_ = new IShip.Info[](1);
            defenderShips_[0] = IShip.Info(0, 0, 0, 0);
        }

        //bytes
        bytes memory result = "";

        //attack health
        for (uint i = 0; i < fleetsConfig().getFleetShipLimit(); i++) {
            if (i < attackerLen) {
                IShip.Info memory attackerShip = attackerShips_[i];
                result = BytesUtils._addBytes(result, attackerShip.health);
            } else {
                result = BytesUtils._addBytes(result, 0);
            }
        }

        //defender health
        for (uint i = 0; i < fleetsConfig().getFleetShipLimit(); i++) {
            if (i < defenderLen) {
                IShip.Info memory defenderShip = defenderShips_[i];
                result = BytesUtils._addBytes(result, defenderShip.health);
            } else {
                result = BytesUtils._addBytes(result, 0);
            }
        }

        //temp round
        uint256 round = 20;

        //battle info bytes array
        bytes[] memory battleInfoBytes = new bytes[](round);

        //battle range
        for (uint i = 0; i < round; i++) {

            //round bytes
            bytes memory roundBytes = "";
            if (i % 2 == 0) {
                (roundBytes, defenderShips_) = _singleRound(0, attackerShips_, defenderShips_);
            } else {
                (roundBytes, attackerShips_) = _singleRound(0, defenderShips_, attackerShips_);
            }

            //append bytes array
            battleInfoBytes[i] = roundBytes;

            //round break
            if (_checkShipsAllHealth(attackerShips_) == 0 || _checkShipsAllHealth(defenderShips_) == 0) {
                break;
            }
        }

        //convert bytes array to bytes
        for (uint i = 0; i < battleInfoBytes.length; i++) {
            bytes memory b = battleInfoBytes[i];
            result = BytesUtils._mergeBytes(result, b);
        }

        //winner
        uint8 winner = 1;
        if (_checkShipsAllHealth(attackerShips_) >= _checkShipsAllHealth(defenderShips_)) {
            winner = 0;
        }
        result = abi.encodePacked(winner, result);

        return result;
    }

    function _checkShipsAllHealth(IShip.Info[] memory ships_) private pure returns (uint16){
        uint16 health = 0;
        for (uint i = 0; i < ships_.length; i++) {
            IShip.Info memory shipInfo = ships_[i];
            health += shipInfo.health;
        }
        return health;
    }

    /**
     *
     */
    function _singleRound(uint8 battleType, IShip.Info[] memory attacker_, IShip.Info[] memory defender_) private view returns (bytes memory, IShip.Info[] memory){

        //from index and to index
        uint8 fromIndex = uint8(_getFirstShipIndex(attacker_));
        uint8 toIndex = uint8(_getFirstShipIndex(defender_));

        //attribute index
        uint8 attributeIndex = 6;

        //attacker ship and defender ship
        IShip.Info memory attackerShip = attacker_[fromIndex];
        IShip.Info memory defenderShip = defender_[toIndex];

        //cause damage
        uint256 damage = shipConfig().getRealDamageByInfo(attackerShip, defenderShip);
        uint16 delta = uint16(damage);

        if (defenderShip.health < delta) {
            defenderShip.health = 0;
        } else {
            defenderShip.health -= delta;
        }

        //create battle info
        BattleInfo memory info = BattleInfo(0x00, battleType, fromIndex, toIndex, attributeIndex, defenderShip.health);

        //battle info to bytes
        return (_battleInfoToBytes(info), defender_);
    }

    function _getFirstShipIndex(IShip.Info[] memory ships_) private pure returns (uint256){
        uint256 index = 0;
        for (uint i = 0; i < ships_.length; i++) {
            IShip.Info memory shipInfo = ships_[i];
            if (shipInfo.health > 0) {
                index = i;
            }
        }
        return index;
    }

    /**
     *
     */
    function _battleInfoToBytes(BattleInfo memory info) private pure returns (bytes memory){
        bytes1 direction = _toDirection(info.battleType, info.fromIndex, info.toIndex);
        bytes memory b = "";
        b = BytesUtils._mergeBytes(b, abi.encodePacked(direction));
        b = BytesUtils._mergeBytes(b, abi.encodePacked(info.attributeIndex));
        b = BytesUtils._mergeBytes(b, abi.encodePacked(info.delta));
        return b;
    }

    /**
     *
     */
    function _toDirection(uint8 a, uint8 b, uint8 c) private pure returns (bytes1){
        require(a <= 3 && b <= 7 && c <= 7);
        bytes1 a_byte = abi.encodePacked(a)[0] << 6;
        bytes1 b_byte = abi.encodePacked(b)[0] << 3;
        bytes1 c_byte = abi.encodePacked(c)[0];
        bytes1 result = a_byte | b_byte | c_byte;
        return result;
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

    // function _random(uint256 randomSize) private returns (uint256){
    //     nonce++;
    //     uint256 difficulty = block.difficulty;
    //     uint256 gaslimit = block.gaslimit;
    //     uint256 number = block.number;
    //     uint256 timestamp = block.timestamp;
    //     uint256 gasprice = tx.gasprice;
    //     uint256 random = uint256(keccak256(abi.encodePacked(nonce, difficulty, gaslimit, number, timestamp, gasprice))) % randomSize;
    //     return random;
    // }

    // uint256 nonce;
}