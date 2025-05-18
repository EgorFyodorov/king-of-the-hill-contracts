// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {KingImplementationV1} from "../src/KingImplementationV1.sol";
import "@openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployScript is Script {
    function run() external {
        // Get private key from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start transactions from the deployer
        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation and proxy through Upgrades
        address proxy = Upgrades.deployTransparentProxy(
            "KingImplementationV1.sol", vm.addr(deployerPrivateKey), abi.encodeCall(KingImplementationV1.initialize, ())
        );

        console.log("Proxy deployed at:", proxy);

        // Get interface to the proxy
        KingImplementationV1 king = KingImplementationV1(proxy);

        console.log("Current king:", king.king());
        console.log("Current prize:", king.currentPrize());

        // Get implementation address
        address implementation = Upgrades.getImplementationAddress(proxy);
        console.log("Implementation deployed at:", implementation);

        vm.stopBroadcast();

        // Print deployment information to console
        console.log("-----------------------------------");
        console.log("Deployment Information (save these):");
        console.log("PROXY_ADDRESS:", vm.toString(proxy));
        console.log("IMPLEMENTATION_ADDRESS:", vm.toString(implementation));
        console.log("DEPLOY_TIMESTAMP:", vm.toString(block.timestamp));
        console.log("-----------------------------------");
    }
}
