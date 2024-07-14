// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Shotgun.sol";

contract DeployShotgun is Script {
    function run() external {
        // Retrieve the private key from the environment variable
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // Start broadcasting the deployment transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the Shotgun contract
        Shotgun shotgun = new Shotgun(vm.envAddress("SELFKISSER"));

        // Log the address of the deployed contract
        console.log("Shotgun contract deployed at:", address(shotgun));

        // Stop broadcasting the deployment transactions
        vm.stopBroadcast();
    }
}
