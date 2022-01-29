// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./utils/ArrayUtils.sol";
import "./utils/Coordinate.sol";
import "./utils/Distance.sol";

import "./model/FleetsModel.sol";
import "./interface/IFleets.sol";
import "./interface/IFleetsConfig.sol";
import "./interface/IRegistry.sol";
import "./interface/IShip.sol";
import "./interface/IAccount.sol";
import "./interface/IHero.sol";
import "./interface/ICommodityERC20.sol";

contract Fleets is FleetsModel, IFleets, IERC721Receiver {
    using ArrayUtils for ArrayUtils;
    using Coordinate for Coordinate;
    using Distance for Distance;

    event userFleetsInformation(address addr, string coordinate, uint256[] attackArray);

    modifier checkIndex(address addr_, uint256 index_){
        require(index_ < userFleetsMap[addr_].length, "userFleet: The index is out of bounds.");
        _;
    }

    function registry() private view returns (IRegistry){
        return IRegistry(registryAddress);
    }

    function fleetsConfig() private view returns (IFleetsConfig){
        return IFleetsConfig(registry().fleetsConfig());
    }

    function account() private view returns (IAccount){
        return IAccount(registry().account());
    }

    function ship() private view returns (IShip){
        return IShip(registry().ship());
    }

    function hero() private view returns (IHero){
        return IHero(registry().hero());
    }

    function shipOwnerOf(uint256 shipId_) external view override returns (address){
        return shipOwnerMap[shipId_];
    }

    function userFleet(address addr_, uint256 index_) public view override returns (Fleet memory){
        Fleet[] memory fleetArray = userFleetsMap[addr_];
        require(index_ < fleetArray.length, "userFleet: The index is out of bounds.");
        return userFleetsMap[addr_][index_];
    }

    function userFleets(address addr_) public view override returns (Fleet[] memory){
        return userFleetsMap[addr_];
    }

    function _stakeShip(address addr_, uint256 tokenId_) private {
        IShip(registry().ship()).safeTransferFrom(addr_, address(this), tokenId_);
        shipOwnerMap[tokenId_] = addr_;
    }

    function _withdrawShip(address addr_, uint256 tokenId_) private {
        require(shipOwnerMap[tokenId_] == addr_, "_withdrawShip: is not owner.");
        IShip(registry().ship()).safeTransferFrom(address(this), addr_, tokenId_);
        delete shipOwnerMap[tokenId_];
    }

    function _stakeHero(address addr_, uint256 tokenId_) private {
        IHero(registry().hero()).safeTransferFrom(addr_, address(this), tokenId_);
        heroOwnerMap[tokenId_] = addr_;
    }

    function _withdrawHero(address addr_, uint256 tokenId_) private {
        require(heroOwnerMap[tokenId_] == addr_, "_withdrawHero: is not owner.");
        IHero(registry().hero()).safeTransferFrom(address(this), addr_, tokenId_);
        delete heroOwnerMap[tokenId_];
    }

    function _fleetShipRemove(address addr_, uint256 fleetIndex_, uint32 shipId_) private {
        uint32[] storage nowArray = userFleetsMap[addr_][fleetIndex_].shipIdArray;

        //index
        (bool exist,uint256 index) = ArrayUtils.indexOf(nowArray, shipId_);
        require(exist, "fleetShipRemove: The ship is not in the fleet.");

        //remove
        uint32 temp = nowArray[index];
        nowArray[index] = nowArray[nowArray.length - 1];
        nowArray[nowArray.length - 1] = temp;
        nowArray.pop();

        //withdraw
        _withdrawShip(addr_, shipId_);
    }

    function _fleetShipAttach(address addr_, uint256 fleetIndex_, uint32 shipId_) private {
        uint32[] storage nowArray = userFleetsMap[addr_][fleetIndex_].shipIdArray;

        //attach
        nowArray.push(shipId_);

        //stake
        _stakeShip(addr_, shipId_);
    }

    function _fleetHeroRemove(address addr_, uint256 fleetIndex_, uint32 heroId_) private {
        uint32[] storage nowArray = userFleetsMap[addr_][fleetIndex_].heroIdArray;

        //index
        (bool exist,uint256 index) = ArrayUtils.indexOf(nowArray, heroId_);
        require(exist, "fleetHeroRemove: The hero is not in the fleet.");

        //remove
        uint32 temp = nowArray[index];
        nowArray[index] = nowArray[nowArray.length - 1];
        nowArray[nowArray.length - 1] = temp;
        nowArray.pop();

        //withdraw
        if (heroId_ != 0) {
            _withdrawHero(addr_, heroId_);
        }

    }

    function _fleetHeroAttach(address addr_, uint256 fleetIndex_, uint32 heroId_) private {
        uint32[] storage nowArray = userFleetsMap[addr_][fleetIndex_].heroIdArray;

        //attach
        nowArray.push(heroId_);

        //stake
        if (heroId_ != 0) {
            _stakeHero(addr_, heroId_);
        }

    }

    function _fleetFormationShip(uint256 fleetIndex_, uint32[] memory shipIdArray_) private {
        Fleet[] memory fleetArray = userFleets(msg.sender);
        uint32[] memory nowArray = fleetArray[fleetIndex_].shipIdArray;

        //remove
        for (uint256 i = 0; i < nowArray.length; i++) {
            if (!ArrayUtils.contains(shipIdArray_, nowArray[i])) {
                _fleetShipRemove(msg.sender, fleetIndex_, nowArray[i]);
            }
        }

        //attach
        for (uint256 i = 0; i < shipIdArray_.length; i++) {
            if (!ArrayUtils.contains(nowArray, shipIdArray_[i])) {
                _fleetShipAttach(msg.sender, fleetIndex_, shipIdArray_[i]);
            }
        }

    }

    function _fleetFormationHero(uint256 fleetIndex_, uint32[] memory heroIdArray_) private {
        Fleet[] memory fleetArray = userFleets(msg.sender);
        uint32[] memory nowArray = fleetArray[fleetIndex_].heroIdArray;

        //remove
        for (uint256 i = 0; i < nowArray.length; i++) {
            _fleetHeroRemove(msg.sender, fleetIndex_, nowArray[i]);
        }

        //remove hero from other fleets
        for (uint256 i = 0; i < heroIdArray_.length; i++) {
            if (heroIdArray_[i] == 0) {
                continue;
            }

            uint256 heroPosition = getHeroPosition(heroIdArray_[i]);
            if (heroPosition == 0) {
                continue;
            }

            _fleetHeroRemove(msg.sender, heroPosition - 1, heroIdArray_[i]);
        }

        //attach
        for (uint256 i = 0; i < heroIdArray_.length; i++) {
            _fleetHeroAttach(msg.sender, fleetIndex_, heroIdArray_[i]);
        }
    }

    function fleetFormationCreateShipHero(uint32[] memory shipIdArray_, uint32[] memory heroIdArray_) external {
        //create fleet
        createFleet();

        //get fleet index
        uint256 fleetIndex = userFleets(msg.sender).length - 1;

        //add user
        if (fleetIndex == 0) {
            account().addUser(msg.sender);
        }

        //fleet formation
        require(shipIdArray_.length == heroIdArray_.length, "fleetFormationCreateWithHero: array length error.");
        fleetFormationShipHero(fleetIndex, shipIdArray_, heroIdArray_);

    }

    function fleetFormationShipHero(uint256 fleetIndex_, uint32[] memory shipIdArray_, uint32[] memory heroIdArray_) public {
        require(fleetsConfig().checkFleetFormationConfig(shipIdArray_), "fleetFormationShipHero: check config failed.");

        _fleetFormationShip(fleetIndex_, shipIdArray_);
        _fleetFormationHero(fleetIndex_, heroIdArray_);

        //event user fleets information
        string memory coordinate = getCoordinateFromAddress(msg.sender);
        uint256[] memory attackArray = fleetsConfig().fleetsAttackArray(msg.sender);
        emit userFleetsInformation(msg.sender, coordinate, attackArray);
    }

    function fleetShipInfo(address user_, uint256 index_) public view returns (IShip.Info[] memory){
        Fleet memory fleet = userFleet(user_, index_);
        uint256 length = fleet.shipIdArray.length;
        IShip.Info[] memory ships = new IShip.Info[](length);
        for (uint i = 0; i < length; i++) {
            uint256 shipId = fleet.shipIdArray[i];
            ships[i] = ship().shipInfo(shipId);
        }
        return ships;
    }

    function _checkFleetStatus(address addr_, uint256 fleetIndex_, uint8 status_) private view returns (bool){
        Fleet memory fleet = userFleet(addr_, fleetIndex_);
        return fleet.status == status_;
    }

    function _changeFleetStatus(
        address addr_,
        uint256 fleetIndex_,
        uint8 status_,
        uint32 target_,
        uint256 start_,
        uint256 end_
    ) private {
        Fleet storage fleet = userFleetsMap[addr_][fleetIndex_];
        fleet.status = status_;
        fleet.target = target_;
        fleet.missionStartTime = uint32(start_);
        fleet.missionEndTime = uint32(end_);
    }

    function createFleet() public override {
        uint256 userFleetLength = userFleets(msg.sender).length;
        uint256 userFleetLimit = fleetsConfig().getUserFleetLimit();
        require(userFleetLimit > userFleetLength, "createFleet: exceeds user fleet limit.");
        userFleetsMap[msg.sender].push(_emptyFleet());
    }

    function _emptyFleet() private pure returns (Fleet memory){
        return Fleet(new uint32[](0), new uint32[](0), 0, 0, 0, 0);
    }

    function getGuardFleet(address addr_) public view override returns (Fleet memory){
        Fleet[] memory fleets = userFleets(addr_);
        for (uint i = 0; i < fleets.length; i++) {
            Fleet memory fleet = fleets[i];
            if (fleet.status == 1) {
                return fleet;
            }
        }
        return _emptyFleet();
    }

    function getCoordinateFromAddress(address userAddress_) public view returns (string memory){
        uint256 userId = account().getUserId(userAddress_);
        return Coordinate.userIdToCoordinateString(userId);
    }

    function goHome(uint256 index_) public {
        uint256 duration = fleetsConfig().getGoHomeDuration(msg.sender, index_);
        _changeFleetStatus(msg.sender, index_, 0, 0, uint32(block.timestamp), uint32(block.timestamp + duration));
    }

    function goMarket(uint256 index_) public {
        uint256 duration = fleetsConfig().getGoMarketDuration(msg.sender, index_);
        _changeFleetStatus(msg.sender, index_, 2, 0, uint32(block.timestamp), uint32(block.timestamp + duration));
    }

    function goBattleByCoordinate(string memory coordinate_, uint256 fleetIndex_) public {

        //coordinate to user id
        uint32 userId = uint32(Coordinate.coordinateStringToUserId(coordinate_));
        address target = account().getUserAddress(userId);

        //require valid address
        require(target != msg.sender, "goBattle: Invalid attack address.");
        require(target != address(0), "goBattle: User does not exist.");

        string memory userCoordinate = Coordinate.userIdToCoordinateString(account().getUserId(msg.sender));
        uint256 second = Distance.getTransportTime(userCoordinate, coordinate_);
        _changeFleetStatus(msg.sender, fleetIndex_, 3, userId, block.timestamp, block.timestamp + second);
    }

    function quickFly(uint256 index_) public {
        (address tokenAddress,uint256 cost) = fleetsConfig().getQuickFlyCost();
        ICommodityERC20(tokenAddress).transferFrom(msg.sender, address(this), cost);
        ICommodityERC20(tokenAddress).burn(cost);
        Fleet storage fleet = userFleetsMap[msg.sender][index_];
        fleet.missionEndTime = fleet.missionStartTime;
    }

    function goHomeInstant(uint256 index_) external {
        goHome(index_);
        quickFly(index_);
    }

    function goMarketInstant(uint256 index_) external {
        goMarket(index_);
        quickFly(index_);
    }

    function goBattleInstant(string memory coordinate_, uint256 index_) external {
        goBattleByCoordinate(coordinate_, index_);
        quickFly(index_);
    }

    function guardHome(uint256 fleetIndex_) external {
        require(_checkFleetStatus(msg.sender, fleetIndex_, 0), "guardHome: The fleet is on a mission.");
        _changeFleetStatus(msg.sender, fleetIndex_, 1, 0, block.timestamp, block.timestamp);
    }

    function cancelGuardHome(uint256 fleetIndex_) external {
        require(_checkFleetStatus(msg.sender, fleetIndex_, 1), "cancelGuardHome: The fleet is not guarding.");
        _changeFleetStatus(msg.sender, fleetIndex_, 0, 0, block.timestamp, block.timestamp);
    }

    function getHeroPosition(uint256 heroId_) public view returns (uint256){
        Fleet[] memory fleets = userFleets(msg.sender);
        for (uint256 i = 0; i < fleets.length; i++) {
            for (uint256 j = 0; j < fleets[i].heroIdArray.length; j++) {
                if (fleets[i].heroIdArray[j] == heroId_) {
                    return i + 1;
                }
            }
        }
        return 0;
    }

    function getFleetsHeroArray() external view returns (uint256[] memory){
        Fleet[] memory fleets = userFleets(msg.sender);
        uint256[] memory heroArray = new uint256[](fleets.length * 4);
        uint256 index = 0;
        for (uint i = 0; i < fleets.length; i++) {
            for (uint j = 0; j < fleets[i].heroIdArray.length; j++) {
                heroArray[index] = fleets[i].heroIdArray[j];
                index++;
            }
        }
        return heroArray;
    }

    function getIdleShipsAndFleets() external view returns (uint256[] memory, Fleet[] memory){
        uint256[] memory idleShips = new uint256[](ship().balanceOf(msg.sender));
        for (uint i = 0; i < idleShips.length; i++) {
            uint256 shipId = ship().tokenOfOwnerByIndex(msg.sender, i);
            idleShips[i] = shipId;
        }
        return (idleShips, userFleets(msg.sender));
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
