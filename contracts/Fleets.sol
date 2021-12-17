// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
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

contract Fleets is FleetsModel, IFleets, Ownable {
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

    function userFleet(address addr_, uint256 index_) public view override returns (Fleet memory){
        Fleet[] memory fleetArray = userFleetsMap[addr_];
        require(index_ < fleetArray.length, "userFleet: The index is out of bounds.");
        return userFleetsMap[addr_][index_];
    }

    function userFleets(address addr_) public view override returns (Fleet[] memory){
        return userFleetsMap[addr_];
    }

    function _stakeShip(address addr_, uint256 tokenId_) private {
        IShip(registry().ship()).operatorTransfer(addr_, address(this), tokenId_);
        shipOwnerMap[tokenId_] = addr_;
    }

    function _withdrawShip(address addr_, uint256 tokenId_) private {
        require(shipOwnerMap[tokenId_] == addr_, "_withdrawShip: is not owner.");
        IShip(registry().ship()).operatorTransfer(address(this), addr_, tokenId_);
        delete shipOwnerMap[tokenId_];
    }

    function _stakeHero(address addr_, uint256 tokenId_) private {
        IHero(registry().hero()).operatorTransfer(addr_, address(this), tokenId_);
        heroOwnerMap[tokenId_] = addr_;
    }

    function _withdrawHero(address addr_, uint256 tokenId_) private {
        require(heroOwnerMap[tokenId_] == addr_, "_withdrawHero: is not owner.");
        IHero(registry().hero()).operatorTransfer(address(this), addr_, tokenId_);
        delete heroOwnerMap[tokenId_];
    }

    function _fleetShipRemove(address addr_, uint256 fleetIndex_, uint256 shipId_) private {
        uint256[] storage nowArray = userFleetsMap[addr_][fleetIndex_].shipIdArray;

        //index
        (bool exist,uint256 index) = ArrayUtils.indexOf(nowArray, shipId_);
        require(exist, "fleetShipRemove: The ship is not in the fleet.");

        //remove
        uint256 temp = nowArray[index];
        nowArray[index] = nowArray[nowArray.length - 1];
        nowArray[nowArray.length - 1] = temp;
        nowArray.pop();

        //withdraw
        _withdrawShip(addr_, shipId_);
    }

    function _fleetShipAttach(address addr_, uint256 fleetIndex_, uint256 shipId_) private {
        uint256[] storage nowArray = userFleetsMap[addr_][fleetIndex_].shipIdArray;

        //attach
        nowArray.push(shipId_);

        //stake
        _stakeShip(addr_, shipId_);
    }

    function _fleetHeroRemove(address addr_, uint256 fleetIndex_, uint256 heroId_) private {
        uint256[] storage nowArray = userFleetsMap[addr_][fleetIndex_].heroIdArray;

        //index
        (bool exist,uint256 index) = ArrayUtils.indexOf(nowArray, heroId_);
        require(exist, "fleetHeroRemove: The hero is not in the fleet.");

        //remove
        uint256 temp = nowArray[index];
        nowArray[index] = nowArray[nowArray.length - 1];
        nowArray[nowArray.length - 1] = temp;
        nowArray.pop();

        //withdraw
        if (heroId_ != 0) {
            _withdrawHero(addr_, heroId_);
        }

    }

    function _fleetHeroAttach(address addr_, uint256 fleetIndex_, uint256 heroId_) private {
        uint256[] storage nowArray = userFleetsMap[addr_][fleetIndex_].heroIdArray;

        //attach
        nowArray.push(heroId_);

        //stake
        if (heroId_ != 0) {
            _stakeHero(addr_, heroId_);
        }

    }

    function _fleetFormationShip(uint256 fleetIndex_, uint256[] memory shipIdArray_) private {
        Fleet[] memory fleetArray = userFleets(_msgSender());
        uint256[] memory nowArray = fleetArray[fleetIndex_].shipIdArray;

        //remove
        for (uint256 i = 0; i < nowArray.length; i++) {
            if (!ArrayUtils.contains(shipIdArray_, nowArray[i])) {
                _fleetShipRemove(_msgSender(), fleetIndex_, nowArray[i]);
            }
        }

        //attach
        for (uint256 i = 0; i < shipIdArray_.length; i++) {
            if (!ArrayUtils.contains(nowArray, shipIdArray_[i])) {
                _fleetShipAttach(_msgSender(), fleetIndex_, shipIdArray_[i]);
            }
        }

    }

    function _fleetFormationHero(uint256 fleetIndex_, uint256[] memory heroIdArray_) private {
        Fleet[] memory fleetArray = userFleets(_msgSender());
        uint256[] memory nowArray = fleetArray[fleetIndex_].heroIdArray;

        //remove
        for (uint256 i = 0; i < nowArray.length; i++) {
            _fleetHeroRemove(_msgSender(), fleetIndex_, nowArray[i]);
        }

        //attach
        for (uint256 i = 0; i < heroIdArray_.length; i++) {
            _fleetHeroAttach(_msgSender(), fleetIndex_, heroIdArray_[i]);
        }
    }

    function fleetFormationCreateShipHero(uint256[] memory shipIdArray_, uint256[] memory heroIdArray_) external {
        //create fleet
        createFleet();

        //get fleet index
        uint256 fleetIndex = userFleets(_msgSender()).length - 1;

        //add user
        if (fleetIndex == 0) {
            account().addUser(_msgSender());
        }

        //fleet formation
        require(shipIdArray_.length == heroIdArray_.length, "fleetFormationCreateWithHero: array length error.");
        fleetFormationShipHero(fleetIndex, shipIdArray_, heroIdArray_);

    }

    function fleetFormationShipHero(uint256 fleetIndex_, uint256[] memory shipIdArray_, uint256[] memory heroIdArray_) public {
        require(fleetsConfig().checkFleetFormationConfig(shipIdArray_), "fleetFormationShipHero: check config failed.");

        _fleetFormationShip(fleetIndex_, shipIdArray_);
        _fleetFormationHero(fleetIndex_, heroIdArray_);

        //event user fleets information
        string memory coordinate = getCoordinateFromAddress(_msgSender());
        uint256[] memory attackArray = fleetsConfig().fleetsAttackArray(_msgSender());
        emit userFleetsInformation(_msgSender(), coordinate, attackArray);
    }

    function _checkFleetStatus(address addr_, uint256 fleetIndex_, FleetStatus status_) private view returns (bool){
        Fleet memory fleet = userFleet(addr_, fleetIndex_);
        return fleet.status == status_;
    }

    function _changeFleetStatus(
        address addr_,
        uint256 fleetIndex_,
        FleetStatus status_,
        address target_,
        uint256 start_,
        uint256 end_
    ) private {
        Fleet storage fleet = userFleetsMap[addr_][fleetIndex_];
        fleet.status = status_;
        fleet.target = target_;
        fleet.missionStartTime = start_;
        fleet.missionEndTime = end_;
    }

    function createFleet() public override {
        uint256 userFleetLength = userFleets(_msgSender()).length;
        uint256 userFleetLimit = fleetsConfig().getUserFleetLimit();
        require(userFleetLimit > userFleetLength, "createFleet: exceeds user fleet limit.");
        userFleetsMap[_msgSender()].push(_emptyFleet());
    }

    function _emptyFleet() private pure returns (Fleet memory){
        return Fleet(FleetStatus.Home, address(0), 0, 0, new uint256[](0), new uint256[](0), Asset(0, 0, 0, 0));
    }

    function getGuardFleet(address addr_) public view override returns (Fleet memory){
        Fleet[] memory fleets = userFleets(addr_);
        for (uint i = 0; i < fleets.length; i++) {
            Fleet memory fleet = fleets[i];
            if (fleet.status == FleetStatus.Guard) {
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
        uint256 duration = fleetsConfig().getGoHomeDuration(_msgSender(), index_);
        _changeFleetStatus(_msgSender(), index_, FleetStatus.Home, _msgSender(), block.timestamp, block.timestamp + duration);
    }

    function goMarket(uint256 index_) public {
        uint256 duration = fleetsConfig().getGoMarketDuration(_msgSender(), index_);
        _changeFleetStatus(_msgSender(), index_, FleetStatus.Market, _msgSender(), block.timestamp, block.timestamp + duration);
    }

    function goBattleByCoordinate(string memory coordinate_, uint256 fleetIndex_) public {

        //coordinate to user id
        uint32 userId = uint32(Coordinate.coordinateStringToUserId(coordinate_));
        address target = account().getUserAddress(userId);

        //require valid address
        require(target != _msgSender(), "goBattle: Invalid attack address.");
        require(target != address(0), "goBattle: User does not exist.");

        string memory userCoordinate = Coordinate.userIdToCoordinateString(account().getUserId(_msgSender()));
        uint256 second = Distance.getTransportTime(userCoordinate, coordinate_);
        _changeFleetStatus(_msgSender(), fleetIndex_, FleetStatus.GoBattle, target, block.timestamp, block.timestamp + second);
    }

    function quickFly(uint256 index_) public {
        Fleet storage fleet = userFleetsMap[_msgSender()][index_];
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
        require(_checkFleetStatus(_msgSender(), fleetIndex_, FleetStatus.Home), "guardHome: The fleet is on a mission.");
        _changeFleetStatus(_msgSender(), fleetIndex_, FleetStatus.Guard, _msgSender(), block.timestamp, block.timestamp);
    }

    function cancelGuardHome(uint256 fleetIndex_) external {
        require(_checkFleetStatus(_msgSender(), fleetIndex_, FleetStatus.Guard), "cancelGuardHome: The fleet is not guarding.");
        _changeFleetStatus(_msgSender(), fleetIndex_, FleetStatus.Home, _msgSender(), block.timestamp, block.timestamp);
    }

}