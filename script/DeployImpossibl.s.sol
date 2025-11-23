// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ImpossiblProtocol} from "../src/Impossibl.sol";

/**
 * @notice Deployment script for ImpossiblProtocol on Worldchain or Celo
 * @dev Supports deployment to both Worldchain and Celo networks
 *      Specify chain via DEPLOY_CHAIN environment variable: "worldchain" or "celo"
 *      RPC URLs are hardcoded in foundry.toml as public endpoints
 * 
 * @dev Usage examples:
 *      Deploy to Worldchain:
 *        DEPLOY_CHAIN=worldchain forge script script/DeployImpossibl.s.sol:DeployImpossibl --rpc-url worldchain --broadcast
 *      
 *      Deploy to Celo:
 *        DEPLOY_CHAIN=celo forge script script/DeployImpossibl.s.sol:DeployImpossibl --rpc-url celo --broadcast
 */
contract DeployImpossibl is Script {
    // Chain IDs
    uint256 constant WORLDCHAIN_CHAIN_ID = 480;
    uint256 constant CELO_CHAIN_ID = 42220;
    
    // Chain names
    string constant CHAIN_WORLDCHAIN = "worldchain";
    string constant CHAIN_CELO = "celo";

    function setUp() public {}

    function run() public {
        // Get private key from environment variable (required)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get target chain from environment variable (default: worldchain)
        string memory deployChain = vm.envOr("DEPLOY_CHAIN", string("worldchain"));
        
        // Get explorer URL from environment variable (optional)
        bool hasExplorer = vm.envExists("EXPLORER_SCAN");
        string memory explorerUrl = hasExplorer ? vm.envString("EXPLORER_SCAN") : "";
        
        address deployer = vm.addr(deployerPrivateKey);
        
        // Determine chain ID and name
        uint256 chainId;
        string memory chainName;
        
        if (keccak256(bytes(deployChain)) == keccak256(bytes(CHAIN_CELO))) {
            chainId = CELO_CHAIN_ID;
            chainName = "Celo";
        } else {
            // Default to Worldchain
            chainId = WORLDCHAIN_CHAIN_ID;
            chainName = "Worldchain";
        }
        
        console.log("==========================================");
        console.log("Deploying ImpossiblProtocol to", chainName);
        console.log("Chain ID:", chainId);
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

