// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./IShip.sol";
import "./IBattle.sol";

interface IBattleConfig {

    function shipHealth(IShip.Info memory ship_) external view returns (uint16);

    function getRealDamage(IBattle.BattleShip memory, IBattle.BattleShip memory) external pure returns (uint256);
}