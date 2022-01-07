// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "../interface/IRegistry.sol";
import "../interface/IBattleConfig.sol";

contract BattleConfig is IBattleConfig {

    address public registryAddress;

    constructor(address registry_) public {
        registryAddress = registry_;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function getRealDamage(IBattle.BattleShip memory attacker_, IBattle.BattleShip memory defender_) external override pure returns (uint32){
        uint32 attack = attacker_.attack;
        uint32 defense = defender_.defense;
        return (attack * attack) / (attack + defense);
    }
}