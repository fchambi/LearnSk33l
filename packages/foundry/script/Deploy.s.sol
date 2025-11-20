//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import { Reputation } from "../contracts/Reputation.sol";
import { EducatorSubscription } from "../contracts/EducatorSubscription.sol";
import { CourseRegistry } from "../contracts/CourseRegistry.sol";
import { LearnToEarn } from "../contracts/LearnToEarn.sol";

/**
 * @notice Main deployment script for Sk33L platform
 * @dev Deploys all contracts in correct order and sets up authorizations
 *
 * Example: yarn deploy # runs this script (without `--file` flag)
 */
contract DeployScript is ScaffoldETHDeploy {
    function run() external ScaffoldEthDeployerRunner {
        // 1. Deploy Reputation contract
        Reputation reputation = new Reputation(deployer);
        console.log("Reputation deployed at:", address(reputation));
        deployments.push(
            Deployment({ name: "Reputation", addr: address(reputation) })
        );
        
        // 2. Deploy EducatorSubscription with Reputation address
        EducatorSubscription subscription = new EducatorSubscription(
            deployer,
            address(reputation)
        );
        console.log("EducatorSubscription deployed at:", address(subscription));
        deployments.push(
            Deployment({ name: "EducatorSubscription", addr: address(subscription) })
        );
        
        // 3. Deploy CourseRegistry
        CourseRegistry courseRegistry = new CourseRegistry();
        console.log("CourseRegistry deployed at:", address(courseRegistry));
        deployments.push(
            Deployment({ name: "CourseRegistry", addr: address(courseRegistry) })
        );
        
        // 4. Deploy LearnToEarn with all contract addresses
        LearnToEarn learnToEarn = new LearnToEarn(
            address(courseRegistry),
            address(subscription),
            address(reputation)
        );
        console.log("LearnToEarn deployed at:", address(learnToEarn));
        deployments.push(
            Deployment({ name: "LearnToEarn", addr: address(learnToEarn) })
        );
        
        // 5. Authorize contracts in Reputation
        reputation.setAuthorized(address(subscription), true);
        console.log("Authorized EducatorSubscription in Reputation");
        
        reputation.setAuthorized(address(learnToEarn), true);
        console.log("Authorized LearnToEarn in Reputation");
        
        console.log("All Sk33L contracts deployed and configured successfully!");
    }
}
