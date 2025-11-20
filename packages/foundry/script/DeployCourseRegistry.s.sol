// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/CourseRegistry.sol";

/**
 * @notice Deploy script for CourseRegistry contract
 * @dev Deploys the course management system for Sk33L platform
 */
contract DeployCourseRegistry is ScaffoldETHDeploy {
    function run() external ScaffoldEthDeployerRunner returns (CourseRegistry) {
        CourseRegistry registry = new CourseRegistry();
        
        // Track deployment
        deployments.push(
            Deployment({ name: "CourseRegistry", addr: address(registry) })
        );
        
        return registry;
    }
}

