// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/LearnToEarn.sol";

/**
 * @notice Deploy script for LearnToEarn contract
 * @dev Requires CourseRegistry, EducatorSubscription, and Reputation addresses
 */
contract DeployLearnToEarn is ScaffoldETHDeploy {
    function run(
        address courseRegistryAddress,
        address subscriptionAddress,
        address reputationAddress
    ) external ScaffoldEthDeployerRunner returns (LearnToEarn) {
        LearnToEarn learnToEarn = new LearnToEarn(
            courseRegistryAddress,
            subscriptionAddress,
            reputationAddress
        );
        
        // Track deployment
        deployments.push(
            Deployment({ name: "LearnToEarn", addr: address(learnToEarn) })
        );
        
        return learnToEarn;
    }
}

