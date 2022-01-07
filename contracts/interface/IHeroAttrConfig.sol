// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./IHero.sol";

interface IHeroAttrConfig {
    function getAttributes(uint256 heroId_) external view returns (uint256[] memory);
}