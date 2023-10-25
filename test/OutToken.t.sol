// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {ManualToken} from "../src/ManualToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on her behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testTransferToken() public {
        // Bob transfers tokens to Alice
        vm.prank(bob);
        uint256 transferAmount = 50;
        ourToken.transfer(alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testTransferWithInsufficientBalance() public {
        uint256 initialBalance = ourToken.balanceOf(bob);
        uint256 transferAmount = initialBalance + 1;

        // Attempt to transfer tokens with an insufficient balance, should revert
        vm.prank(bob);
        // vm.expectRevert("ERC20InsufficientBalance");
        vm.expectRevert();
        ourToken.transfer(alice, transferAmount);

        // Balance of 'bob' should remain unchanged
        assertEq(ourToken.balanceOf(bob), initialBalance);
    }

    function testFailsTransferToZeroAddress() public {
        // Attempt to transfer tokens to a zero address.
        // This should intentionally fail.
        uint256 transferAmount = 500;
        bool success = ourToken.transfer(address(0), transferAmount);
        assertEq(success, false);
    }

    function testFailedTransferInsufficientBalance() public {
        // Attempt to transfer tokens with insufficient balance.
        // This should intentionally fail.
        uint256 transferAmount = STARTING_BALANCE + 1;
        bool success = ourToken.transfer(bob, transferAmount);
        assertEq(success, false);
    }
}

contract ManualTokenTest is Test {
    ManualToken public manualToken;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        manualToken = new ManualToken();
        manualToken.transfer(bob, 20 ether);
    }

    function testInitialValues() public {
        // Test the initial name, total supply, and decimals.
        assertEq(manualToken.name(), "Manual Token");
        assertEq(manualToken.totalSupply(), 100 ether);
        assertEq(manualToken.decimals(), 18);
    }

    function testTransferManualToken() public {
        // Test transferring tokens from one account to another.
        vm.prank(bob);
        manualToken.transfer(alice, 10 ether);

        assertEq(manualToken.balanceOf(alice), 10 ether);
        assertEq(manualToken.balanceOf(bob), 100 ether - 10 ether);
    }

    function testTransferInsufficientBalance() public {
        // Test transferring tokens with insufficient balance, should revert.
        (bool success, ) = address(manualToken).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                alice,
                101 ether
            )
        );
        assertEq(success, false); // The call should revert, which means success is false.
    }

    function testTransferToZeroAddress() public {
        // Test transferring tokens to the zero address, should revert.
        bool success;
        try manualToken.transfer(address(0), 10 ether) {
            success = true; // The transfer succeeded, but it should revert.
        } catch (bytes memory /* revertReason */) {
            success = false; // The transfer reverted, which is expected.
        }
        assertEq(success, false);
    }

    function testTransferWithPreviousBalanceCheck() public {
        // Test transferring tokens with an additional balance check.
        uint256 initialBalanceAlice = manualToken.balanceOf(alice);
        uint256 initialBalanceBob = manualToken.balanceOf(bob);

        manualToken.transfer(bob, 10 ether);

        assertEq(manualToken.balanceOf(alice), initialBalanceAlice - 10 ether);
        assertEq(manualToken.balanceOf(bob), initialBalanceBob + 10 ether);
    }
}
