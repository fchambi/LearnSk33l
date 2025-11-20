// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import { Reputation } from "../contracts/Reputation.sol";
import { EducatorSubscription } from "../contracts/EducatorSubscription.sol";
import { CourseRegistry } from "../contracts/CourseRegistry.sol";
import { LearnToEarn } from "../contracts/LearnToEarn.sol";

/**
 * @notice Script to seed test data into deployed Sk33L contracts
 * @dev Run after deployment to populate contracts with sample data for frontend testing
 */
contract SeedData is ScaffoldETHDeploy {
    // Test addresses
    address constant EDUCATOR_1 = 0x1234567890123456789012345678901234567890;
    address constant EDUCATOR_2 = 0x2345678901234567890123456789012345678901;
    address constant STUDENT_1 = 0x3456789012345678901234567890123456789012;
    
    function run() external {
        // Get deployed contract addresses from the latest deployment
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get contract instances (update these addresses with your deployed contracts)
        Reputation reputation = Reputation(vm.envAddress("REPUTATION_ADDRESS"));
        EducatorSubscription subscription = EducatorSubscription(payable(vm.envAddress("SUBSCRIPTION_ADDRESS")));
        CourseRegistry courseRegistry = CourseRegistry(vm.envAddress("COURSE_REGISTRY_ADDRESS"));
        
        console.log("Starting data seeding...");
        console.log("Reputation:", address(reputation));
        console.log("Subscription:", address(subscription));
        console.log("CourseRegistry:", address(courseRegistry));
        
        // Seed Educator 1
        seedEducator1(subscription, courseRegistry);
        
        // Seed Educator 2
        seedEducator2(subscription, courseRegistry);
        
        console.log("\nData seeding completed successfully!");
        console.log("You can now test the frontend with pre-loaded data");
        
        vm.stopBroadcast();
    }
    
    function seedEducator1(EducatorSubscription subscription, CourseRegistry courseRegistry) internal {
        console.log("\nSeeding Educator 1:", EDUCATOR_1);
        
        // Impersonate educator 1
        vm.stopBroadcast();
        vm.startBroadcast(EDUCATOR_1);
        
        // Set monthly price: 0.01 ETH
        subscription.setMonthlyPrice(0.01 ether);
        console.log("- Set monthly price: 0.01 ETH");
        
        // Create 3 courses
        courseRegistry.createCourse("ipfs://QmSk33L1Course1Metadata");
        console.log("- Created course 1");
        
        courseRegistry.createCourse("ipfs://QmSk33L1Course2Metadata");
        console.log("- Created course 2");
        
        courseRegistry.createCourse("ipfs://QmSk33L1Course3Metadata");
        console.log("- Created course 3");
        
        vm.stopBroadcast();
    }
    
    function seedEducator2(EducatorSubscription subscription, CourseRegistry courseRegistry) internal {
        console.log("\nSeeding Educator 2:", EDUCATOR_2);
        
        // Impersonate educator 2
        vm.startBroadcast(EDUCATOR_2);
        
        // Set monthly price: 0.02 ETH
        subscription.setMonthlyPrice(0.02 ether);
        console.log("- Set monthly price: 0.02 ETH");
        
        // Create 2 courses
        courseRegistry.createCourse("ipfs://QmSk33L2Course1Metadata");
        console.log("- Created course 1");
        
        courseRegistry.createCourse("ipfs://QmSk33L2Course2Metadata");
        console.log("- Created course 2");
        
        vm.stopBroadcast();
    }
}

