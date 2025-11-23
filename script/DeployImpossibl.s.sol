// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ImpossiblProtocol} from "../src/Impossibl.sol";

/**
 * @notice Deployment script for ImpossiblProtocol on Worldchain
 * @dev This script is hardcoded to deploy on Worldchain (Chain ID: 480)
 *      RPC URL is hardcoded in foundry.toml as public Alchemy endpoint
 *      Use: forge script script/DeployImpossibl.s.sol:DeployImpossibl --rpc-url worldchain --broadcast
 */
contract DeployImpossibl is Script {
    // Worldchain Chain ID: 480
    uint256 constant WORLDCHAIN_CHAIN_ID = 480;
    // Worldchain public RPC URL (configured in foundry.toml)
    // https://worldchain-mainnet.g.alchemy.com/public

    function setUp() public {}

    function run() public {
        // Get private key from environment variable (required)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get explorer URL from environment variable (optional, e.g., https://worldscan.io)
        bool hasExplorer = vm.envExists("EXPLORER_SCAN");
        string memory explorerUrl = hasExplorer ? vm.envString("EXPLORER_SCAN") : "";
        
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("Deploying ImpossiblProtocol to Worldchain");
        console.log("Chain ID:", WORLDCHAIN_CHAIN_ID);
        console.log("Deployer address:", deployer);
        console.log("==========================================");
        
        vm.startBroadcast(deployerPrivateKey);
        
        ImpossiblProtocol impossibl = new ImpossiblProtocol();
        
        vm.stopBroadcast();
        
        console.log("\n==========================================");
        console.log("Deployment successful!");
        console.log("Contract address:", address(impossibl));
        if (hasExplorer) {
            console.log("Explorer:", string.concat(explorerUrl, "/address/", vm.toString(address(impossibl))));
        }
        console.log("==========================================");
    }
}

