# Damn Vulnerable DeFi - Foundry edition

**A set of challenges to hack implementations of DeFi in Ethereum.**

Featuring flash loans, price oracles, governance, NFTs, lending pools, smart contract wallets, timelocks, and more!

Created by [@tinchoabbate](https://twitter.com/tinchoabbate)

Visit [damnvulnerabledefi.xyz](https://damnvulnerabledefi.xyz)

## Acknowledgements

- Created by [@tinchoabbate](https://twitter.com/tinchoabbate)
- [Foundry](https://github.com/gakonst/foundry)
- [Foundry Book](https://book.getfoundry.sh/)

## How to play

### Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
```

### Update Foundry

```bash
foundryup
```

### Clone repo and install dependencies

```bash
git clone git@github.com:StErMi/forge-damn-vulnerable-defi.git
cd forge-damn-vulnerable-defi
git submodule update --init --recursive
```

### Run a solution

```bash
# example forge test --match-contract PuppetTest
forge test --match-contract NAME_OF_THE_TEST
```

### Create your own solutions

Create a new test `CHALLENGE.t.sol` in the `src/test/` directory and inherit from `BaseTest.sol`.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {stdError} from "forge-std/stdlib.sol";
import {Utilities} from "../utils/Utilities.sol";
import {BaseTest} from "../BaseTest.sol";

// ADD ALL YOUR IMPORTS HERE

contract TrusterTest is BaseTest {

    // ADD ALL YOUR VARIABLES HERE

    // attacker adddress
    address payable attacker;

    constructor() {
        // setup the needed user accordly
        string[] memory labels = new string[](1);
        labels[0] = "Attacker";

        preSetup(1, labels);
    }

    function setUp() public override {
        super.setUp();

        attacker = users[0];

        // setup contracts

    }


    function test_Exploit() public {
        // don't change this
        runTest();
    }

    function exploit() internal override {
        /** CODE YOUR EXPLOIT HERE */

        // add your attack code here
    }

    function success() internal override {
        /** SUCCESS CONDITIONS */

        // import your success conditions asserts here
    }
}
```

What you need to do:

1. Add as many users as needed for the test in the `constructor`
2. Replace `// setup contracts` in `setUp()` with all the test environment setup. Deploy your contract, setup the users funds, etc.
3. Replace `// add your attack code here` in `exploit()` with your exploit code.
4. Replace `// import your success conditions asserts here` in `success()` with your success conditions asserts.

## Disclaimer

All Solidity code, practices and patterns in this repository are DAMN VULNERABLE and for educational purposes only.

DO NOT USE IN PRODUCTION.
