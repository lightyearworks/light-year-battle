const ArrayUtils = artifacts.require("ArrayUtils");
const Coordinate = artifacts.require("Coordinate");
const Distance = artifacts.require("Distance");
const BytesUtils = artifacts.require("BytesUtils");

const ShipConfig = artifacts.require("ShipConfig");
const HeroConfig = artifacts.require("HeroConfig");
const FleetsConfig = artifacts.require("FleetsConfig");
const ExploreConfig = artifacts.require("ExploreConfig");
const BaseConfig = artifacts.require("BaseConfig");
const ResearchConfig = artifacts.require("ResearchConfig");
const ClaimConfig = artifacts.require("ClaimConfig");
const MiningConfig = artifacts.require("MiningConfig");

const Registry = artifacts.require("Registry");
const Ship = artifacts.require("Ship");
const Hero = artifacts.require("Hero");
const Explore = artifacts.require("Explore");
const Battle = artifacts.require("Battle");

const Account = artifacts.require("Account");
const AccountProxy = artifacts.require("AccountProxy");
const Fleets = artifacts.require("Fleets");
const FleetsProxy = artifacts.require("FleetsProxy");

const Base = artifacts.require("Base");
const Research = artifacts.require("Research");

const WBNB = artifacts.require("CommodityERC20");
const SwapFactory = artifacts.require("UniswapV2Factory");
const SwapRouter = artifacts.require("UniswapV2Router02");

const Staking = artifacts.require("Staking");
const MasterChef = artifacts.require("MasterChef");
const CommodityERC20 = artifacts.require("CommodityERC20");


module.exports = async function (deployer) {

    //libraries
    await deployer.deploy(ArrayUtils);
    await deployer.deploy(Coordinate);
    await deployer.deploy(Distance);
    await deployer.link(ArrayUtils, Fleets);
    await deployer.link(Coordinate, Fleets);
    await deployer.link(Distance, Fleets);
    await deployer.deploy(BytesUtils);
    await deployer.link(BytesUtils, Battle);

    //registry
    await deployer.deploy(Registry);
    const registry = await Registry.deployed();

    //fleets config
    await deployer.deploy(FleetsConfig, registry.address);
    const fleetsConfig = await FleetsConfig.deployed();
    await registry.setFleetsConfig(fleetsConfig.address);

    //ship config
    await deployer.deploy(ShipConfig, registry.address);
    const shipConfig = await ShipConfig.deployed();
    await registry.setShipConfig(shipConfig.address);

    //hero config
    await deployer.deploy(HeroConfig, registry.address);
    const heroConfig = await HeroConfig.deployed();
    await registry.setHeroConfig(heroConfig.address);

    //explore config
    await deployer.deploy(ExploreConfig, registry.address);
    const exploreConfig = await ExploreConfig.deployed();
    await registry.setExploreConfig(exploreConfig.address);

    //base config
    await deployer.deploy(BaseConfig, registry.address);
    const baseConfig = await BaseConfig.deployed();
    await registry.setBaseConfig(baseConfig.address);

    //research config
    await deployer.deploy(ResearchConfig, registry.address);
    const researchConfig = await ResearchConfig.deployed();
    await registry.setResearchConfig(researchConfig.address);

    //claim config
    await deployer.deploy(ClaimConfig, registry.address);
    const claimConfig = await ClaimConfig.deployed();
    await registry.setClaimConfig(claimConfig.address);

    //mining config
    await deployer.deploy(MiningConfig, registry.address);
    const miningConfig = await MiningConfig.deployed();
    await registry.setMiningConfig(miningConfig.address);

    //battle
    await deployer.deploy(Battle, registry.address);
    const battle = await Battle.deployed();
    await registry.setBattle(battle.address);

    //explore
    await deployer.deploy(Explore, registry.address);
    const explore = await Explore.deployed();
    await registry.setExplore(explore.address);

    //account
    await deployer.deploy(AccountProxy, registry.address);
    const accountProxy = await AccountProxy.deployed();
    await deployer.deploy(Account);
    const account = await Account.deployed();
    await accountProxy.setAccount(account.address);
    await registry.setAccount(accountProxy.address);

    //fleets
    await deployer.deploy(FleetsProxy, registry.address);
    const fleetsProxy = await FleetsProxy.deployed();
    await deployer.deploy(Fleets);
    const fleets = await Fleets.deployed();
    await fleetsProxy.setFleets(fleets.address);
    await registry.setFleets(fleetsProxy.address);

    //ship
    await deployer.deploy(Ship, registry.address);
    const ship = await Ship.deployed();
    await registry.setShip(ship.address);

    //hero
    await deployer.deploy(Hero, registry.address);
    const hero = await Hero.deployed();
    await registry.setHero(hero.address);

    //base
    await deployer.deploy(Base, registry.address);
    const base = await Base.deployed();
    await registry.setBase(base.address);

    //research
    await deployer.deploy(Research, registry.address);
    const research = await Research.deployed();
    await registry.setResearch(research.address);

    //tokens
    await deployer.deploy(CommodityERC20, "name", "symbol", registry.address);
    const lightYearCoin = await CommodityERC20.deployed();
    await registry.setTokenLightCoin(lightYearCoin.address);
    await deployer.deploy(CommodityERC20, "name", "symbol", registry.address);
    const iron = await CommodityERC20.deployed();
    await deployer.deploy(CommodityERC20, "name", "symbol", registry.address);
    const gold = await CommodityERC20.deployed();
    await deployer.deploy(CommodityERC20, "name", "symbol", registry.address);
    const silicate = await CommodityERC20.deployed();
    await deployer.deploy(CommodityERC20, "name", "symbol", registry.address);
    const energy = await CommodityERC20.deployed();
    await registry.setTokenIron(iron.address);
    await registry.setTokenGold(gold.address);
    await registry.setTokenSilicate(silicate.address);
    await registry.setTokenEnergy(energy.address);

    //==========================================================================================
    //swap
    await deployer.deploy(WBNB, "name", "symbol", registry.address);
    const wbnb = await WBNB.deployed();
    await deployer.deploy(SwapFactory);
    const swapFactory = await SwapFactory.deployed();
    await deployer.deploy(SwapRouter, swapFactory.address, wbnb.address);
    const swapRouter = await SwapRouter.deployed();
    await registry.setStableToken(wbnb.address);
    await registry.setUniswapV2Router(swapRouter.address);

    //master chef
    await deployer.deploy(CommodityERC20, "name", "symbol", registry.address);
    const cake = await CommodityERC20.deployed();
    const dev = '0x9b0B0076B9e6caFc8f0b9cEED9A5190c0fCa91ea';
    await deployer.deploy(MasterChef, cake.address, dev, "10000000000000000000000", 1);
    const masterChef = await MasterChef.deployed();

    //lp
    await deployer.deploy(CommodityERC20, "name", "symbol", registry.address);
    const lp_aaa = await CommodityERC20.deployed();
    await deployer.deploy(CommodityERC20, "name", "symbol", registry.address);
    const lp_bbb = await CommodityERC20.deployed();
    await deployer.deploy(CommodityERC20, "name", "symbol", registry.address);
    const lp_ccc = await CommodityERC20.deployed();
    await deployer.deploy(CommodityERC20, "name", "symbol", registry.address);
    const lp_ddd = await CommodityERC20.deployed();

    //add
    await masterChef.add(100, lp_aaa.address, true);
    await masterChef.add(100, lp_bbb.address, true);
    await masterChef.add(100, lp_ccc.address, true);
    await masterChef.add(100, lp_ddd.address, true);

    //staking
    await deployer.deploy(Staking, registry.address);
    const staking = await Staking.deployed();
    await staking.addPool(masterChef.address, 1, lp_aaa.address, cake.address);
    await staking.addPool(masterChef.address, 2, lp_bbb.address, cake.address);
    await staking.addPool(masterChef.address, 3, lp_ccc.address, cake.address);
    await staking.addPool(masterChef.address, 4, lp_ddd.address, cake.address);
    await staking.addAsset(iron.address, 1000000);
    await staking.addAsset(gold.address, 1000000);
    await staking.addAsset(silicate.address, 1000000);
    await staking.addAsset(energy.address, 1000000);
};
