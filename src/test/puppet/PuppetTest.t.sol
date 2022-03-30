// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {stdError, stdCheats} from "forge-std/stdlib.sol";

import {Utilities} from "../utils/Utilities.sol";
import {BaseTest} from "../BaseTest.sol";

import "../../DamnValuableToken.sol";
import "../../uniswap-v1/IUniswapV1Exchange.sol";
import "../../uniswap-v1/IUniswapV1Factory.sol";
import "../../puppet/PuppetPool.sol";

// string constant uniswapExchangeTemplateArtifact = "artifacts/build-uniswap-v1/UniswapV1Exchange.json";
// string constant uniswapFactoryTemplateArtifact = "artifacts/build-uniswap-v1/UniswapV1Factory.json";


contract PuppetTest is BaseTest, stdCheats {

    uint256 UNISWAP_INITIAL_TOKEN_RESERVE = 10 ether; 
    uint256 UNISWAP_INITIAL_ETH_RESERVE = 10 ether; 

    uint256 ATTACKER_INITIAL_TOKEN_BALANCE = 1000 ether; 
    uint256 ATTACKER_INITIAL_ETH_BALANCE = 25 ether;

    uint256 POOL_INITIAL_TOKEN_BALANCE = 100000 ether; 

    DamnValuableToken token;
    PuppetPool lendingPool;
    IUniswapV1Exchange uniswapExchange;


    address attacker;

    constructor() {
        string[] memory labels = new string[](1);
        labels[0] = "Attacker";

        preSetup(1, ATTACKER_INITIAL_ETH_BALANCE, labels);
    }

    function setUp() public override {
        super.setUp();
        vm.label(address(this), "deployer");
        // vm.deal(address(this), null);

        attacker = users[0];


        // check that the attacker has only 25 ether
        assertEq(attacker.balance, ATTACKER_INITIAL_ETH_BALANCE);

        // Deploy token to be traded in Uniswap
        token = new DamnValuableToken();
        vm.label(address(token), "DamnValuableToken");

        // Deploy a exchange that will be used as the factory template
        address _exchangeTemplate = deployCode("artifacts/build-uniswap-v1/UniswapV1Exchange.json");
        IUniswapV1Exchange exchangeTemplate = IUniswapV1Exchange(_exchangeTemplate);

        // Deploy factory, initializing it with the address of the template exchange
        address _uniswapFactory = deployCode("artifacts/build-uniswap-v1/UniswapV1Factory.json");
        IUniswapV1Factory uniswapFactory = IUniswapV1Factory(_uniswapFactory);
        uniswapFactory.initializeFactory(address(exchangeTemplate));

        // Create a new exchange for the token, and retrieve the deployed exchange's address
        address exchangeAddress = uniswapFactory.createExchange{gas: 1e6}(address(token));
        uniswapExchange = IUniswapV1Exchange(exchangeAddress);
        vm.label(address(uniswapExchange), "UniswapV1Exchange");

        // Deploy the lending pool
        lendingPool = new PuppetPool(address(token), address(uniswapExchange));
        vm.label(address(lendingPool), "PuppetPool");

        // Add initial token and ETH liquidity to the pool
        token.approve(address(uniswapExchange), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapExchange.addLiquidity{value: UNISWAP_INITIAL_ETH_RESERVE, gas: 1e6}(
            0, // min_liquidity
            UNISWAP_INITIAL_TOKEN_RESERVE,
            block.timestamp * 2 // deadline
        );
    }

    
    function test_Exploit() public {
        runTest();
    }

    function exploit() internal override {
        /** CODE YOUR EXPLOIT HERE */

        
    }

    function success() internal override {
        /** SUCCESS CONDITIONS */


    }
}
