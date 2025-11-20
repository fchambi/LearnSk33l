// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { Reputation } from "../contracts/Reputation.sol";
import { EducatorSubscription } from "../contracts/EducatorSubscription.sol";
import { CourseRegistry } from "../contracts/CourseRegistry.sol";

/**
 * @notice Simple script to seed test data using Anvil default accounts
 * @dev Run this after deployment to have data ready in the frontend
 */
contract SeedTestData is Script {
    function run() external {
        // Read deployment addresses from latest broadcast
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/broadcast/Deploy.s.sol/31337/run-latest.json");
        string memory json = vm.readFile(path);
        
        // Parse contract addresses from deployment
        address reputationAddr = vm.parseJsonAddress(json, ".transactions[0].contractAddress");
        address subscriptionAddr = vm.parseJsonAddress(json, ".transactions[1].contractAddress");
        address courseRegistryAddr = vm.parseJsonAddress(json, ".transactions[2].contractAddress");
        
        console.log("=== Seeding Test Data ===");
        console.log("Reputation:", reputationAddr);
        console.log("EducatorSubscription:", subscriptionAddr);
        console.log("CourseRegistry:", courseRegistryAddr);
        console.log("");
        
        // Get contract instances
        EducatorSubscription subscription = EducatorSubscription(payable(subscriptionAddr));
        CourseRegistry courseRegistry = CourseRegistry(courseRegistryAddr);
        
        // Anvil default account private keys
        uint256 educator1Key = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        uint256 educator2Key = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        
        // Seed Educator 1
        vm.startBroadcast(educator1Key);
        subscription.setMonthlyPrice(0.01 ether);
        courseRegistry.createCourse("ipfs://QmWeb3CourseIntroduction");
        courseRegistry.createCourse("ipfs://QmSolidityBasics");
        courseRegistry.createCourse("ipfs://QmSmartContractSecurity");
        console.log("Educator 1 (0x7099...79C8):");
        console.log("  - Price: 0.01 ETH/month");
        console.log("  - Created 3 courses");
        vm.stopBroadcast();
        
        // Seed Educator 2
        vm.startBroadcast(educator2Key);
        subscription.setMonthlyPrice(0.02 ether);
        courseRegistry.createCourse("ipfs://QmDeFiMasterclass");
        courseRegistry.createCourse("ipfs://QmNFTDevelopment");
        console.log("\nEducator 2 (0x3C44...293BC):");
        console.log("  - Price: 0.02 ETH/month");
        console.log("  - Created 2 courses");
        vm.stopBroadcast();
        
        console.log("\n=== Seeding Complete! ===");
        console.log("Frontend is ready to test with pre-loaded data");
    }
}

