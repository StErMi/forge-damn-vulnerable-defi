// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {stdError, stdCheats} from "forge-std/stdlib.sol";

import {Utilities} from "../utils/Utilities.sol";
import {BaseTest} from "../BaseTest.sol";

import "../../DamnValuableToken.sol";
// import "../../puppet-v2/PuppetV2Pool.sol";

interface WETH9 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}


contract PuppetTest is BaseTest, stdCheats {

    uint256 UNISWAP_INITIAL_TOKEN_RESERVE = 100 ether; 
    uint256 UNISWAP_INITIAL_WETH_RESERVE = 10 ether; 

    uint256 ATTACKER_INITIAL_TOKEN_BALANCE = 10000 ether; 
    uint256 ATTACKER_INITIAL_ETH_BALANCE = 20 ether;
    uint256 POOL_INITIAL_TOKEN_BALANCE = 1000000 ether;


    DamnValuableToken token;
    WETH9 weth;
    // PuppetV2Pool lendingPool;


    address attacker;

    constructor() {
        string[] memory labels = new string[](1);
        labels[0] = "Attacker";

        preSetup(1, ATTACKER_INITIAL_ETH_BALANCE, labels);
    }

    function setUp() public override {
        super.setUp();
        vm.label(address(this), "deployer");
        
        // check that the attacker has only 20 ether
        assertEq(attacker.balance, ATTACKER_INITIAL_ETH_BALANCE);

        token = new DamnValuableToken();
        // weth = new WETH9();

        address _WETH9 = deployCode("artifacts/WETH9.json");
        weth = WETH9(_WETH9);
    }

    
    function test_Exploit() public {
        runTest();
    }

    function exploit() internal override {
        /** CODE YOUR EXPLOIT HERE */
        vm.startPrank(attacker);
        

        vm.stopPrank();
    }

    function success() internal override {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool   
    }
}
