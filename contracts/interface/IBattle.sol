// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./IShip.sol";

interface IBattle {

    struct BattleInfo {
        bytes1 direction;
        uint8 battleType;
        uint8 fromIndex;
        uint8 toIndex;
        uint8 attributeIndex;
        uint32 delta;
    }

    function battleByShipInfo(IShip.Info[] memory attackerShips_, IShip.Info[] memory defenderShips_) external view returns (bytes memory);
}