// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./IShip.sol";

interface IExploreConfig {

    function getMayDropByLevel(uint256 level_) external pure returns (uint256[] memory);

    function getRealDropByLevel(uint256 level_, uint256[] memory heroIdArray) external view returns (uint256[] memory);

    function pirateShips(uint256 level_) external pure returns (IShip.Info[] memory);

    function exploreDuration() external pure returns(uint256);
}