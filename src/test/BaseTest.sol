// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Utilities} from "./utils/Utilities.sol";

contract BaseTest is Test {
    Utilities internal utils;

    address payable[] users;
    uint256 numOfUsers;
    uint256 etherAmountForUser;
    string[] userLabels;

    function preSetup(uint _numOfUsers, string[] memory _userLabels) internal {
        numOfUsers = _numOfUsers;
        userLabels = _userLabels;
        etherAmountForUser = 100 ether;
    }

    function preSetup(uint _numOfUsers, uint256 _etherAmountForUser, string[] memory _userLabels) internal {
        numOfUsers = _numOfUsers;
        userLabels = _userLabels;
        etherAmountForUser = _etherAmountForUser;
    }

    function setUp() public virtual {
        // setup utils
        utils = new Utilities();

        // setup users
        users = utils.createUsers(numOfUsers, etherAmountForUser, userLabels);
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
