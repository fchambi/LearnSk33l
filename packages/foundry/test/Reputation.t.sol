// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/Reputation.sol";

contract ReputationTest is Test {
    Reputation public reputation;
    address public owner;
    address public authorizedContract;
    address public unauthorizedContract;
    address public educator;
    address public learner;

    event AuthorizedUpdated(address indexed contractAddr, bool isAuthorized);
    event EducatorScoreIncreased(address indexed educator, uint256 amount, uint256 newScore);
    event LearnerScoreIncreased(address indexed learner, uint256 amount, uint256 newScore);

    function setUp() public {
        owner = address(this);
        authorizedContract = vm.addr(1);
        unauthorizedContract = vm.addr(2);
        educator = vm.addr(3);
        learner = vm.addr(4);

        reputation = new Reputation(owner);
    }

    // Constructor tests
    function testConstructorSetsOwner() public view {
        assertEq(reputation.owner(), owner);
    }

    function testConstructorRevertsOnZeroAddress() public {
        vm.expectRevert(Reputation.ZeroAddress.selector);
        new Reputation(address(0));
    }

    // Authorization tests
    function testSetAuthorized() public {
        vm.expectEmit(true, false, false, true);
        emit AuthorizedUpdated(authorizedContract, true);
        
        reputation.setAuthorized(authorizedContract, true);
        assertTrue(reputation.authorized(authorizedContract));
    }

    function testSetAuthorizedCanRevoke() public {
        reputation.setAuthorized(authorizedContract, true);
        assertTrue(reputation.authorized(authorizedContract));
        
        vm.expectEmit(true, false, false, true);
        emit AuthorizedUpdated(authorizedContract, false);
        
        reputation.setAuthorized(authorizedContract, false);
        assertFalse(reputation.authorized(authorizedContract));
    }

    function testSetAuthorizedRevertsIfNotOwner() public {
        vm.prank(unauthorizedContract);
        vm.expectRevert(Reputation.NotOwner.selector);
        reputation.setAuthorized(authorizedContract, true);
    }

    function testSetAuthorizedRevertsOnZeroAddress() public {
        vm.expectRevert(Reputation.ZeroAddress.selector);
        reputation.setAuthorized(address(0), true);
    }

    // Educator score tests
    function testIncreaseEducatorScore() public {
        reputation.setAuthorized(authorizedContract, true);
        
        vm.prank(authorizedContract);
        vm.expectEmit(true, false, false, true);
        emit EducatorScoreIncreased(educator, 100, 100);
        
        reputation.increaseEducatorScore(educator, 100);
        assertEq(reputation.educatorScore(educator), 100);
    }

    function testIncreaseEducatorScoreMultipleTimes() public {
        reputation.setAuthorized(authorizedContract, true);
        
        vm.startPrank(authorizedContract);
        reputation.increaseEducatorScore(educator, 100);
        reputation.increaseEducatorScore(educator, 50);
        vm.stopPrank();
        
        assertEq(reputation.educatorScore(educator), 150);
    }

    function testIncreaseEducatorScoreRevertsIfNotAuthorized() public {
        vm.prank(unauthorizedContract);
        vm.expectRevert(Reputation.NotAuthorized.selector);
        reputation.increaseEducatorScore(educator, 100);
    }

    function testIncreaseEducatorScoreRevertsOnZeroAddress() public {
        reputation.setAuthorized(authorizedContract, true);
        
        vm.prank(authorizedContract);
        vm.expectRevert(Reputation.ZeroAddress.selector);
        reputation.increaseEducatorScore(address(0), 100);
    }

    function testIncreaseEducatorScoreRevertsOnZeroAmount() public {
        reputation.setAuthorized(authorizedContract, true);
        
        vm.prank(authorizedContract);
        vm.expectRevert(Reputation.InvalidAmount.selector);
        reputation.increaseEducatorScore(educator, 0);
    }

    // Learner score tests
    function testIncreaseLearnerScore() public {
        reputation.setAuthorized(authorizedContract, true);
        
        vm.prank(authorizedContract);
        vm.expectEmit(true, false, false, true);
        emit LearnerScoreIncreased(learner, 100, 100);
        
        reputation.increaseLearnerScore(learner, 100);
        assertEq(reputation.learnerScore(learner), 100);
    }

    function testIncreaseLearnerScoreMultipleTimes() public {
        reputation.setAuthorized(authorizedContract, true);
        
        vm.startPrank(authorizedContract);
        reputation.increaseLearnerScore(learner, 100);
        reputation.increaseLearnerScore(learner, 75);
        vm.stopPrank();
        
        assertEq(reputation.learnerScore(learner), 175);
    }

    function testIncreaseLearnerScoreRevertsIfNotAuthorized() public {
        vm.prank(unauthorizedContract);
        vm.expectRevert(Reputation.NotAuthorized.selector);
        reputation.increaseLearnerScore(learner, 100);
    }

    function testIncreaseLearnerScoreRevertsOnZeroAddress() public {
        reputation.setAuthorized(authorizedContract, true);
        
        vm.prank(authorizedContract);
        vm.expectRevert(Reputation.ZeroAddress.selector);
        reputation.increaseLearnerScore(address(0), 100);
    }

    function testIncreaseLearnerScoreRevertsOnZeroAmount() public {
        reputation.setAuthorized(authorizedContract, true);
        
        vm.prank(authorizedContract);
        vm.expectRevert(Reputation.InvalidAmount.selector);
        reputation.increaseLearnerScore(learner, 0);
    }

    // Integration test
    function testMultipleAuthorizedContracts() public {
        address contract1 = vm.addr(10);
        address contract2 = vm.addr(11);
        
        reputation.setAuthorized(contract1, true);
        reputation.setAuthorized(contract2, true);
        
        vm.prank(contract1);
        reputation.increaseEducatorScore(educator, 50);
        
        vm.prank(contract2);
        reputation.increaseEducatorScore(educator, 30);
        
        assertEq(reputation.educatorScore(educator), 80);
    }
}

