// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/EducatorSubscription.sol";
import "../contracts/Reputation.sol";

/**
 * @notice Deploy script for EducatorSubscription contract
 * @dev Requires Reputation contract address as parameter
 */
contract DeployEducatorSubscription is ScaffoldETHDeploy {
    function run(address reputationAddress) external ScaffoldEthDeployerRunner returns (EducatorSubscription) {
        EducatorSubscription subscription = new EducatorSubscription(
            deployer,
            reputationAddress
        );
        
        // Track deployment
        deployments.push(
            Deployment({ name: "EducatorSubscription", addr: address(subscription) })
        );
        
        return subscription;
    }
}

