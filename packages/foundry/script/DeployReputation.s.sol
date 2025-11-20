// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/Reputation.sol";

/**
 * @notice Deploy script for Reputation contract
 * @dev Deploys the reputation tracking system for Sk33L platform
 */
contract DeployReputation is ScaffoldETHDeploy {
    function run() external ScaffoldEthDeployerRunner returns (Reputation) {
        Reputation reputation = new Reputation(deployer);
        
        // Track deployment
        deployments.push(
            Deployment({ name: "Reputation", addr: address(reputation) })
        );
        
        return reputation;
    }
}

