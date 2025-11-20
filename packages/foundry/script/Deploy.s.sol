//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import { DeployReputation } from "./DeployReputation.s.sol";
import { DeployEducatorSubscription } from "./DeployEducatorSubscription.s.sol";
import { DeployCourseRegistry } from "./DeployCourseRegistry.s.sol";
import { DeployLearnToEarn } from "./DeployLearnToEarn.s.sol";
import { Reputation } from "../contracts/Reputation.sol";

/**
 * @notice Main deployment script for Sk33L platform
 * @dev Deploys all contracts in correct order and sets up authorizations
 *
 * Example: yarn deploy # runs this script (without `--file` flag)
 */
contract DeployScript is ScaffoldETHDeploy {
    function run() external ScaffoldEthDeployerRunner {
        // 1. Deploy Reputation contract
        DeployReputation deployReputation = new DeployReputation();
        Reputation reputation = deployReputation.run();
        
        // 2. Deploy EducatorSubscription with Reputation address
        DeployEducatorSubscription deploySubscription = new DeployEducatorSubscription();
        address subscription = address(deploySubscription.run(address(reputation)));
        
        // 3. Deploy CourseRegistry
        DeployCourseRegistry deployCourseRegistry = new DeployCourseRegistry();
        address courseRegistry = address(deployCourseRegistry.run());
        
        // 4. Deploy LearnToEarn with all contract addresses
        DeployLearnToEarn deployLearnToEarn = new DeployLearnToEarn();
        address learnToEarn = address(deployLearnToEarn.run(
            courseRegistry,
            subscription,
            address(reputation)
        ));
        
        // 5. Authorize contracts in Reputation
        reputation.setAuthorized(subscription, true);
        reputation.setAuthorized(learnToEarn, true);
    }
}
