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

    function shipHealth(IShip.Info memory ship_) external override view returns (uint16){
        return ship_.quality * 2;
    }

    function getRealDamage(IBattle.BattleShip memory attacker_, IBattle.BattleShip memory defender_) external override pure returns (uint256){
        return 50;
    }
}