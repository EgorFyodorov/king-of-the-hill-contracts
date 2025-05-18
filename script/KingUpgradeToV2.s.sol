// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/KingImplementationV2.sol";
import {Upgrades} from "@openzeppelin-foundry-upgrades/Upgrades.sol";

contract KingUpgradeToV2 is Script {
    function run() external {
        // Get private key from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Addresses of existing contracts (should be passed through environment variables)
        address proxyAddress = vm.envAddress("KING_PROXY_ADDRESS");

        // Start transactions from the deployer
        vm.startBroadcast(deployerPrivateKey);

        // Prepare initialization data for V2
        bytes memory initData = abi.encodeCall(KingImplementationV2.initializeV2, ());

        // Update implementation through standard Upgrades
        Upgrades.upgradeProxy(proxyAddress, "KingImplementationV2.sol", initData);

        console.log("Proxy upgraded to V2 and initialized");

        // Get implementation address
        address implementation = Upgrades.getImplementationAddress(proxyAddress);
        console.log("Implementation address:", implementation);

        // Get interface of the updated contract
        KingImplementationV2 king = KingImplementationV2(proxyAddress);

        // Output current state information
        console.log("Current king:", king.king());
        console.log("Current prize:", king.currentPrize());
        console.log("Total claims:", king.totalClaims());
        console.log("Fee percentage:", king.feePercentage());

        vm.stopBroadcast();

        // Print upgrade information to console
        console.log("-----------------------------------");
        console.log("Upgrade Information (save these):");
        console.log("PROXY_ADDRESS:", vm.toString(proxyAddress));
        console.log("IMPLEMENTATION_ADDRESS:", vm.toString(implementation));
        console.log("UPGRADE_TIMESTAMP:", vm.toString(block.timestamp));
        console.log("-----------------------------------");
    }
}
