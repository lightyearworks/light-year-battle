// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./model/AccountModel.sol";
import "./interface/IAccount.sol";
import "./interface/IRegistry.sol";

contract Account is AccountModel, IAccount, Ownable {

    modifier onlyOperator(){
        require(IRegistry(registryAddress).isOperator(_msgSender()), "onlyOperator: require operator.");
        _;
    }

    function getTotalUsers() public override view returns (uint256){
        return totalUsers;
    }

    function getUserId(address addr_) external override view returns (uint256) {
        return userAddressMap[addr_];
    }

    function getUserAddress(uint256 userId_) external override view returns (address){
        return userIdMap[userId_];
    }

    function userExploreLevel(address addr_) external override view returns (uint256){
        return userExploreLevelMap[addr_];
    }

    function addUser(address addr_) public override onlyOperator {
        require(userAddressMap[addr_] == 0, "addUser: user already exists.");
        uint32 userId = totalUsers + 1;
        userIdMap[userId] = addr_;
        userAddressMap[addr_] = userId;
        totalUsers++;
    }

    function addExploreLevel(address addr_) external override onlyOperator {
        userExploreLevelMap[addr_]++;
    }

    function saveBattleHistory(address addr_, bytes memory history_) external override onlyOperator {
        userBattleHistoryMap[addr_].push(history_);
    }
}