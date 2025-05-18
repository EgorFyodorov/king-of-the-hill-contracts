// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/KingImplementationV2.sol";
import {Upgrades} from "@openzeppelin-foundry-upgrades/Upgrades.sol";

contract KingStatus is Script {
    function run() external view {
        // Get proxy address from environment variables
        address proxyAddress = vm.envAddress("KING_PROXY_ADDRESS");

        // Create interface to proxy
        KingImplementationV2 king = KingImplementationV2(proxyAddress);

        // Get implementation address using Upgrades
        address implementation = Upgrades.getImplementationAddress(proxyAddress);

        // Get current status
        address currentKing = king.king();
        uint256 currentPrize = king.currentPrize();
        uint256 totalClaims = king.totalClaims();
        uint256 feePercentage = king.feePercentage();

        // Get owner
        address owner = king.owner();

        // Print status information
        console.log("-----------------------------------");
        console.log("King of the Hill Status Report");
        console.log("-----------------------------------");
        console.log("Proxy Address:", proxyAddress);
        console.log("Implementation Address:", implementation);
        console.log("Owner:", owner);
        console.log("Current King:", currentKing);
        console.log("Current Prize:", currentPrize, "wei");
        console.log("Current Prize (ETH):", currentPrize / 1e18, "ETH");
        console.log("Total Claims:", totalClaims);
        console.log("Fee Percentage:", feePercentage);
        console.log("Fee Percentage (percent):", feePercentage / 100);
        console.log("-----------------------------------");

        // Get claim count for current king
        uint256 kingClaimCount = king.claimCount(currentKing);
        console.log("Current King's Claim Count:", kingClaimCount);

        // Get pending withdrawals
        uint256 kingPendingWithdrawal = king.pendingWithdrawals(currentKing);
        uint256 ownerPendingWithdrawal = king.pendingWithdrawals(owner);

        console.log("Current King's Pending Withdrawal:", kingPendingWithdrawal, "wei");
        console.log("Owner's Pending Withdrawal:", ownerPendingWithdrawal, "wei");
        console.log("-----------------------------------");

        // Calculate minimum bid required
        uint256 minBid = currentPrize + (currentPrize * feePercentage) / 10000;
        console.log("Minimum Bid Required:", minBid, "wei");
        console.log("Minimum Bid Required (ETH):", minBid / 1e18, "ETH");
        console.log("-----------------------------------");
    }
}
