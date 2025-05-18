// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {KingImplementationV1} from "../src/KingImplementationV1.sol";
import {KingImplementationV2} from "../src/KingImplementationV2.sol";
import {UnsafeUpgrades} from "@openzeppelin-foundry-upgrades/Upgrades.sol";

contract KingUpgradeTest is Test {
    address public proxy;
    KingImplementationV1 public kingV1;
    KingImplementationV2 public kingV2;
    address public owner;
    address public user1;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        vm.startPrank(owner);

        // Deploy V1 implementation
        address implV1 = address(new KingImplementationV1());

        // Deploy proxy through UnsafeUpgrades
        proxy =
            UnsafeUpgrades.deployTransparentProxy(implV1, owner, abi.encodeCall(KingImplementationV1.initialize, ()));

        // Get typed interface for interaction
        kingV1 = KingImplementationV1(proxy);

        vm.stopPrank();
    }

    function test_UpgradeToV2() public {
        // User becomes a king
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        kingV1.claimThrone{value: 1 ether}();
        vm.stopPrank();

        // Upgrade on behalf of the owner through UnsafeUpgrades
        vm.startPrank(owner);

        // Deploy V2 implementation
        address implV2 = address(new KingImplementationV2());

        // Upgrade proxy and initialize V2
        UnsafeUpgrades.upgradeProxy(proxy, implV2, abi.encodeCall(KingImplementationV2.initializeV2, ()));

        // Get V2 interface
        kingV2 = KingImplementationV2(proxy);

        // Verify state after upgrade
        assertEq(kingV2.feePercentage(), 500); // 5%
        assertEq(kingV2.totalClaims(), 0);
        assertEq(kingV2.king(), user1);
        assertEq(kingV2.currentPrize(), 1 ether);

        vm.stopPrank();
    }
}
