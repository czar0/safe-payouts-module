// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {SafePayoutsModule, ISafeModuleManager} from "../src/SafePayoutsModule.sol";

contract SafePayoutsModuleTest is Test {
    SafePayoutsModule payoutsModule;
    address payable alice;
    address payable bob;
    address payable charlie;

    // Deploying the contract
    function setUp() public {
        payoutsModule = new SafePayoutsModule();
        alice = payable(makeAddr("alice"));
        bob = payable(makeAddr("bob"));
        charlie = payable(makeAddr("charlie"));
    }

    // Check the deployer is in the operators list
    function test_setUpState() public {
        assertTrue(payoutsModule.operators(address(this)));
    }

    // Operators should be able to add a new payout
    function test_addPayout_OperatorIsAllowed() public {
        vm.prank(address(this));
        payoutsModule.addPayout(alice, 1 ether);
        assertEq(payoutsModule.payouts(alice), 1 ether);
        assertEq(payoutsModule.beneficiaries(0), alice);
        assertFalse(payoutsModule.paid(alice));
        assertEq(payoutsModule.indexes(alice), 0);
    }

    // Operators should not be able to add payouts with invalid address as beneficiary
    function test_addPayout_RevertIf_InvalidAddress() public {
        vm.prank(address(this));
        vm.expectRevert("address not valid");
        payoutsModule.addPayout(address(0), 1 ether);
    }

    // Operators should not be able to add payouts for same beneficiary
    function test_addPayout_RevertIf_AddressAlreadyExist() public {
        vm.startPrank(address(this));
        payoutsModule.addPayout(alice, 1 ether);
        vm.expectRevert("address already exists");
        payoutsModule.addPayout(alice, 2 ether);
    }

    // Operators should not be able to add payouts with 0 value
    function test_addPayout_RevertIf_ValueIsZero() public {
        vm.prank(address(this));
        vm.expectRevert("amount too low");
        payoutsModule.addPayout(alice, 0);
    }

    // Non-Operators should not be able to add a new payout
    function test_addPayout_RevertIf_NotOperator() public {
        vm.prank(address(123));
        vm.expectRevert("no permissions");
        payoutsModule.addPayout(alice, 1 ether);
    }

    // Operators should be able to add payouts after a deletion
    function test_addPayout_AfterDeletion() public {
        vm.startPrank(address(this));
        payoutsModule.addPayout(alice, 1 ether); // index = 0
        payoutsModule.addPayout(bob, 2 ether); // index = 1
        payoutsModule.addPayout(charlie, 3 ether); // index = 2
        payoutsModule.removePayout(alice); // charlie -> index = 0
        payoutsModule.addPayout(alice, 1 ether); // index = 2
        assertEq(payoutsModule.beneficiaries(0), charlie);
        assertEq(payoutsModule.indexes(charlie), 0);
        assertEq(payoutsModule.beneficiaries(1), bob);
        assertEq(payoutsModule.indexes(bob), 1);
        assertEq(payoutsModule.beneficiaries(2), alice);
        assertEq(payoutsModule.indexes(alice), 2);
    }

    // Operators should be able to remove an existing payout
    function test_removePayout_OperatorIsAllowed() public {
        vm.startPrank(address(this));
        payoutsModule.addPayout(alice, 1 ether);
        payoutsModule.addPayout(bob, 1 ether);
        payoutsModule.removePayout(alice);
        assertEq(payoutsModule.payouts(alice), 0);
        assertFalse(payoutsModule.paid(alice));
        assertEq(payoutsModule.indexes(bob), 0);
    }

    // Operators should not be able to remove payouts providing an invalid address as beneficiary
    function test_removePayout_RevertIf_InvalidAddress() public {
        vm.startPrank(address(this));
        vm.expectRevert("address not valid");
        payoutsModule.removePayout(address(0));
    }

    // Removing payout call should fail when an operator try to remove a payout for a beneficiary not in the list
    function test_removePayout_RevertIf_AddressNotExist() public {
        vm.startPrank(address(this));
        payoutsModule.addPayout(alice, 1 ether);
        vm.expectRevert("address do not exist");
        payoutsModule.removePayout(bob);
    }

    // Non-Operators should not be able to remove a payout
    function test_removePayout_RevertIf_NotOperator() public {
        vm.prank(address(123));
        vm.expectRevert("no permissions");
        payoutsModule.removePayout(alice);
    }
}
