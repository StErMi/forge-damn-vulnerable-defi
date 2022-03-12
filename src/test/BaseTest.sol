// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {Utilities} from "./utils/Utilities.sol";

contract BaseTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;

    address payable[] users;
    uint256 numOfUsers;
    string[] userLabels;

    function preSetup(uint _numOfUsers, string[] memory _userLabels) internal {
        numOfUsers = _numOfUsers;
        userLabels = _userLabels;
    }

    function setUp() public virtual {
        // setup utils
        utils = new Utilities();

        // setup users
        users = utils.createUsers(numOfUsers, 100 ether, userLabels);
    }

    function runTest() public {
        // run the exploit
        exploit();

        // verify the exploit
        success();
    }

    function exploit() internal virtual {
        /* IMPLEMENT YOUR EXPLOIT */
    }

    function success() internal virtual {
        /* IMPLEMENT YOUR EXPLOIT */
    }
}
