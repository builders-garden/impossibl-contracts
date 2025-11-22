// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ImpossiblProtocol} from "../src/Impossibl.sol";

contract DeployImpossibl is Script {
    function setUp() public {}

    function run() public {
        // Get private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("Deploying ImpossiblProtocol to Worldchain...");
        console.log("Deployer address:", vm.addr(deployerPrivateKey));
        
        vm.startBroadcast(deployerPrivateKey);
        
        ImpossiblProtocol impossibl = new ImpossiblProtocol();
        
        vm.stopBroadcast();
        
        console.log("ImpossiblProtocol deployed at:", address(impossibl));
    }
}

