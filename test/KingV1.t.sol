// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {KingImplementationV1} from "../src/KingImplementationV1.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract KingV1Test is Test {
    TransparentUpgradeableProxy public proxy;
    ProxyAdmin public proxyAdmin;
    KingImplementationV1 public implementation;
    address public owner;
    address public user1;
    address public user2;

    event ThroneClaimed(address indexed previousKing, address indexed newKing, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);

        // Deploy proxy admin
        proxyAdmin = new ProxyAdmin(owner);
        proxyAdmin.transferOwnership(owner);

        // Deploy implementation
        implementation = new KingImplementationV1();

        // Deploy proxy
        proxy = new TransparentUpgradeableProxy(
            address(implementation), address(proxyAdmin), abi.encodeCall(KingImplementationV1.initialize, ())
        );

        vm.stopPrank();
    }

    function test_InitialState() public view {
        KingImplementationV1 king = KingImplementationV1(address(proxy));
        assertEq(king.king(), owner);
        assertEq(king.currentPrize(), 0);
    }

    function test_ClaimThrone() public {
        KingImplementationV1 king = KingImplementationV1(address(proxy));
        vm.deal(user1, 1 ether);

        vm.startPrank(user1);
        king.claimThrone{value: 1 ether}();
        vm.stopPrank();

        // Проверяем, что средства сразу идут на счет предыдущего короля
        assertEq(king.pendingWithdrawals(owner), 1 ether);
        assertEq(king.currentPrize(), 1 ether);
    }

    function test_ClaimThroneWithHigherBid() public {
        KingImplementationV1 king = KingImplementationV1(address(proxy));
        vm.deal(user1, 1 ether);
        vm.deal(user2, 2 ether);

        // Проверяем первое событие
        vm.startPrank(user1);
        vm.expectEmit(true, true, false, true);
        emit ThroneClaimed(owner, user1, 1 ether);
        king.claimThrone{value: 1 ether}();
        vm.stopPrank();

        // Проверяем второе событие
        vm.startPrank(user2);
        vm.expectEmit(true, true, false, true);
        emit ThroneClaimed(user1, user2, 2 ether);
        king.claimThrone{value: 2 ether}();
        vm.stopPrank();

        assertEq(king.king(), user2);
        assertEq(king.currentPrize(), 2 ether);
        assertEq(king.pendingWithdrawals(user1), 2 ether);
    }

    function test_WithdrawFunds() public {
        KingImplementationV1 king = KingImplementationV1(address(proxy));
        vm.deal(user1, 1 ether);

        vm.startPrank(user1);
        king.claimThrone{value: 1 ether}();
        vm.stopPrank();

        // Проверяем, что предыдущий король может вывести средства
        uint256 ownerBalanceBefore = owner.balance;
        vm.prank(owner);
        king.withdraw();
        assertEq(owner.balance, ownerBalanceBefore + 1 ether);
        assertEq(king.pendingWithdrawals(owner), 0);
    }

    function test_RevertWhen_ClaimThroneWithLowerBid() public {
        KingImplementationV1 king = KingImplementationV1(address(proxy));
        vm.deal(user1, 2 ether);
        vm.deal(user2, 1 ether);

        vm.startPrank(user1);
        king.claimThrone{value: 2 ether}();
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert("Need to pay more than current prize");
        king.claimThrone{value: 1 ether}();
        vm.stopPrank();
    }

    function test_RevertWhen_WithdrawNoFunds() public {
        KingImplementationV1 king = KingImplementationV1(address(proxy));
        vm.startPrank(user1);
        vm.expectRevert("No funds to withdraw");
        king.withdraw();
        vm.stopPrank();
    }
}
