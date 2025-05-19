// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {KingImplementationV2} from "../src/KingImplementationV2.sol";
import {KingImplementationV1} from "../src/KingImplementationV1.sol";
import {UnsafeUpgrades} from "@openzeppelin-foundry-upgrades/Upgrades.sol";

contract KingV2Test is Test {
    address public proxy;
    KingImplementationV2 public king;
    address public owner;
    address public user1;
    address public user2;

    event ThroneClaimed(address indexed previousKing, address indexed newKing, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event FeePercentageUpdated(uint256 oldFee, uint256 newFee);

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);

        // Deploy V1 implementation
        address implV1 = address(new KingImplementationV1());

        // Deploy proxy through UnsafeUpgrades
        address proxyV1 =
            UnsafeUpgrades.deployTransparentProxy(implV1, owner, abi.encodeCall(KingImplementationV1.initialize, ()));

        // Deploy V2 implementation
        address implV2 = address(new KingImplementationV2());

        // Upgrade to V2 and initialize V2
        UnsafeUpgrades.upgradeProxy(proxyV1, implV2, abi.encodeCall(KingImplementationV2.initializeV2, ()));

        proxy = proxyV1;

        // Get typed interface for interaction
        king = KingImplementationV2(proxy);

        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(king.feePercentage(), 500); // 5%
        assertEq(king.totalClaims(), 0);
    }

    function test_FeeCalculation() public {
        vm.deal(user1, 2 ether);

        // Check event when the first king change occurs
        vm.startPrank(user1);
        vm.expectEmit(true, true, false, true);
        emit ThroneClaimed(owner, user1, 2 ether);
        king.claimThrone{value: 2 ether}();
        vm.stopPrank();

        // Verify funds distribution
        assertEq(king.pendingWithdrawals(owner), 2 ether); // 0.1 ETH fee + 1.9 ETH as previous king
        assertEq(king.currentPrize(), 2 ether); // Full amount as new prize
    }

    function test_TotalClaimsTracking() public {
        vm.deal(user1, 2 ether);
        vm.deal(user2, 3 ether);

        vm.startPrank(user1);
        king.claimThrone{value: 2 ether}();
        vm.stopPrank();

        assertEq(king.totalClaims(), 1);
        assertEq(king.claimCount(user1), 1);

        // Check first king change
        assertEq(king.pendingWithdrawals(owner), 2 ether); // 0.1 ETH fee + 1.9 ETH as previous king
        assertEq(king.currentPrize(), 2 ether); // Full amount as new prize

        vm.startPrank(user2);
        king.claimThrone{value: 3 ether}();
        vm.stopPrank();

        assertEq(king.totalClaims(), 2);
        assertEq(king.claimCount(user2), 1);

        // Check second king change
        assertEq(king.pendingWithdrawals(owner), 2.15 ether); // 0.1 ETH + 1.9 ETH + 0.15 ETH fee
        assertEq(king.pendingWithdrawals(user1), 2.85 ether); // 95% of 3 ETH
        assertEq(king.currentPrize(), 3 ether); // Full amount as new prize
    }

    function test_SetFeePercentage() public {
        vm.startPrank(owner);

        vm.expectEmit(true, false, false, true);
        emit FeePercentageUpdated(500, 300);
        king.setFeePercentage(300);

        assertEq(king.feePercentage(), 300);
        vm.stopPrank();
    }

    function test_RevertWhen_SetFeePercentageTooHigh() public {
        vm.startPrank(owner);
        vm.expectRevert("Fee cannot exceed 10%");
        king.setFeePercentage(1100);
        vm.stopPrank();
    }

    function test_RevertWhen_SetFeePercentageNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        king.setFeePercentage(300);
        vm.stopPrank();
    }

    function test_ClaimThroneWithFee() public {
        vm.deal(user1, 2 ether);

        vm.startPrank(user1);
        king.claimThrone{value: 2 ether}();
        vm.stopPrank();

        // Verify funds distribution
        assertEq(king.pendingWithdrawals(owner), 2 ether); // 0.1 ETH fee + 1.9 ETH as previous king
        assertEq(king.currentPrize(), 2 ether); // Full amount as new prize
    }

    function test_MultipleClaimsWithFee() public {
        vm.deal(user1, 2 ether);
        vm.deal(user2, 3 ether);

        // First king change
        vm.startPrank(user1);
        king.claimThrone{value: 2 ether}();
        vm.stopPrank();

        // Check first king change
        assertEq(king.pendingWithdrawals(owner), 2 ether); // 0.1 ETH fee + 1.9 ETH as previous king
        assertEq(king.currentPrize(), 2 ether); // Full amount as new prize

        // Second king change
        vm.startPrank(user2);
        king.claimThrone{value: 3 ether}();
        vm.stopPrank();

        // Check second king change
        assertEq(king.pendingWithdrawals(owner), 2.15 ether); // 0.1 ETH + 1.9 ETH + 0.15 ETH fee
        assertEq(king.pendingWithdrawals(user1), 2.85 ether); // 95% of 3 ETH
        assertEq(king.currentPrize(), 3 ether); // Full amount as new prize
    }

    function test_RevertWhen_ClaimAmountTooLow() public {
        vm.deal(user1, 2 ether);
        vm.deal(user2, 2.1 ether);

        // First user claims throne
        vm.startPrank(user1);
        king.claimThrone{value: 2 ether}();
        vm.stopPrank();

        // Second user tries to claim with amount that's too low
        vm.startPrank(user2);
        vm.expectRevert("Need to pay more than current prize plus fee");
        king.claimThrone{value: 2.1 ether}();
        vm.stopPrank();
    }

    function test_ClaimWithMinimumAmount() public {
        vm.deal(user1, 2 ether);

        // Calculate minimum required amount (2 ETH + 5% = 2.1 ETH)
        uint256 minRequired = 2 ether + (2 ether * 500) / 10000;
        // Add 0.01 ETH to make it strictly greater than minimum
        uint256 claimAmount = minRequired + 0.01 ether;

        vm.deal(user2, claimAmount);

        // First user claims throne
        vm.startPrank(user1);
        king.claimThrone{value: 2 ether}();
        vm.stopPrank();

        // Second user claims with amount strictly greater than minimum
        vm.startPrank(user2);
        king.claimThrone{value: claimAmount}();
        vm.stopPrank();

        // Calculate expected amount for first user (claimAmount - 5% fee)
        uint256 expectedAmount = claimAmount - (claimAmount * 500) / 10000;

        // Verify first user got their stake back plus profit
        assertEq(king.pendingWithdrawals(user1), expectedAmount);
        assertTrue(expectedAmount > 2 ether);

        // Verify second user is now king
        assertEq(king.king(), user2);

        // Verify new prize is set to full amount
        assertEq(king.currentPrize(), claimAmount);
    }
}
