// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBattle {

    struct BattleShip {
        uint32 health;
        uint32 attack;
        uint32 defense;
    }

    struct BattleInfo {
        bytes1 direction;
        uint8 battleType;
        uint8 fromIndex;
        uint8 toIndex;
        uint8 attributeIndex;
        uint32 delta;
    }

}