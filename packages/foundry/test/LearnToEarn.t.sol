// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/LearnToEarn.sol";
import "../contracts/CourseRegistry.sol";
import "../contracts/EducatorSubscription.sol";
import "../contracts/Reputation.sol";

contract LearnToEarnTest is Test {
    LearnToEarn public learnToEarn;
    CourseRegistry public courseRegistry;
    EducatorSubscription public subscription;
    Reputation public reputation;
    
    address public owner;
    address public educator;
    address public student;
    
    uint256 constant MONTHLY_PRICE = 0.1 ether;
    uint256 constant MIN_SCORE = 70;
    uint256 constant LEARNER_POINTS = 100;
    uint256 constant EDUCATOR_POINTS = 50;
    string constant METADATA_URI = "ipfs://QmTest123";
    
    uint256 public courseId;

    event CourseCompleted(
        address indexed student,
        address indexed educator,
        uint256 indexed courseId,
        uint256 score,
        uint256 learnerPoints,
        uint256 educatorPoints
    );

    function setUp() public {
        owner = vm.addr(1);
        educator = vm.addr(2);
        student = vm.addr(3);
        
        // Deploy all contracts
        vm.startPrank(owner);
        reputation = new Reputation(owner);
        subscription = new EducatorSubscription(owner, address(reputation));
        courseRegistry = new CourseRegistry();
        learnToEarn = new LearnToEarn(
            address(courseRegistry),
            address(subscription),
            address(reputation)
        );
        
        // Authorize contracts in Reputation
        reputation.setAuthorized(address(subscription), true);
        reputation.setAuthorized(address(learnToEarn), true);
        vm.stopPrank();
        
        // Setup educator plan and course
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        vm.prank(educator);
        courseId = courseRegistry.createCourse(METADATA_URI);
        
        // Fund student
        vm.deal(student, 10 ether);
    }

    // Constructor tests
    function testConstructorSetsContracts() public view {
        assertEq(address(learnToEarn.courseRegistry()), address(courseRegistry));
        assertEq(address(learnToEarn.educatorSubscription()), address(subscription));
        assertEq(address(learnToEarn.reputation()), address(reputation));
    }

    function testConstructorRevertsOnZeroAddresses() public {
        vm.expectRevert(LearnToEarn.ZeroAddress.selector);
        new LearnToEarn(address(0), address(subscription), address(reputation));
        
        vm.expectRevert(LearnToEarn.ZeroAddress.selector);
        new LearnToEarn(address(courseRegistry), address(0), address(reputation));
        
        vm.expectRevert(LearnToEarn.ZeroAddress.selector);
        new LearnToEarn(address(courseRegistry), address(subscription), address(0));
    }

    function testConstants() public view {
        assertEq(learnToEarn.MIN_SCORE(), MIN_SCORE);
        assertEq(learnToEarn.LEARNER_POINTS(), LEARNER_POINTS);
        assertEq(learnToEarn.EDUCATOR_POINTS(), EDUCATOR_POINTS);
    }

    // Complete course tests
    function testCompleteCourseWithActiveSubscription() public {
        // Student subscribes
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Student completes course
        vm.prank(student);
        vm.expectEmit(true, true, true, true);
        emit CourseCompleted(student, educator, courseId, 85, LEARNER_POINTS, EDUCATOR_POINTS);
        
        learnToEarn.completeCourse(courseId, 85);
        
        // Check completion
        assertTrue(learnToEarn.courseCompleted(student, courseId));
        assertTrue(learnToEarn.hasCompletedCourse(student, courseId));
        
        // Check reputation increased
        assertEq(reputation.learnerScore(student), LEARNER_POINTS);
        // Educator gets points from subscription (10) + course completion (50)
        assertEq(reputation.educatorScore(educator), 10 + EDUCATOR_POINTS);
    }

    function testCompleteCourseWithMinimumScore() public {
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        vm.prank(student);
        learnToEarn.completeCourse(courseId, MIN_SCORE);
        
        assertTrue(learnToEarn.courseCompleted(student, courseId));
    }

    function testCompleteCourseRevertsWithoutSubscription() public {
        vm.prank(student);
        vm.expectRevert(LearnToEarn.NoActiveSubscription.selector);
        learnToEarn.completeCourse(courseId, 85);
    }

    function testCompleteCourseRevertsWithExpiredSubscription() public {
        // Student subscribes for 1 month
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Move past expiry
        vm.warp(block.timestamp + 31 days);
        
        // Try to complete course
        vm.prank(student);
        vm.expectRevert(LearnToEarn.NoActiveSubscription.selector);
        learnToEarn.completeCourse(courseId, 85);
    }

    function testCompleteCourseRevertsIfScoreTooLow() public {
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        vm.prank(student);
        vm.expectRevert(LearnToEarn.ScoreTooLow.selector);
        learnToEarn.completeCourse(courseId, MIN_SCORE - 1);
    }

    function testCompleteCourseRevertsIfAlreadyCompleted() public {
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        vm.startPrank(student);
        learnToEarn.completeCourse(courseId, 85);
        
        vm.expectRevert(LearnToEarn.AlreadyCompleted.selector);
        learnToEarn.completeCourse(courseId, 90);
        vm.stopPrank();
    }

    function testCompleteCourseRevertsIfCourseInactive() public {
        // Deactivate course
        vm.prank(educator);
        courseRegistry.setCourseActive(courseId, false);
        
        // Student subscribes
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Try to complete inactive course
        vm.prank(student);
        vm.expectRevert(LearnToEarn.CourseNotActive.selector);
        learnToEarn.completeCourse(courseId, 85);
    }

    function testCompleteCourseRevertsIfCourseDoesNotExist() public {
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        vm.prank(student);
        vm.expectRevert(CourseRegistry.CourseDoesNotExist.selector);
        learnToEarn.completeCourse(999, 85);
    }

    // Multiple completions tests
    function testStudentCanCompleteMultipleCourses() public {
        // Create another course
        vm.prank(educator);
        uint256 courseId2 = courseRegistry.createCourse("ipfs://QmTest456");
        
        // Student subscribes
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Complete both courses
        vm.startPrank(student);
        learnToEarn.completeCourse(courseId, 85);
        learnToEarn.completeCourse(courseId2, 90);
        vm.stopPrank();
        
        assertTrue(learnToEarn.courseCompleted(student, courseId));
        assertTrue(learnToEarn.courseCompleted(student, courseId2));
        
        // Learner gets points for each course
        assertEq(reputation.learnerScore(student), LEARNER_POINTS * 2);
        // Educator gets subscription points (10) + completion points for both courses (50 * 2)
        assertEq(reputation.educatorScore(educator), 10 + (EDUCATOR_POINTS * 2));
    }

    function testMultipleStudentsCanCompletesameCourse() public {
        address student2 = vm.addr(4);
        vm.deal(student2, 10 ether);
        
        // Both students subscribe
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        vm.prank(student2);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Both complete the course
        vm.prank(student);
        learnToEarn.completeCourse(courseId, 85);
        
        vm.prank(student2);
        learnToEarn.completeCourse(courseId, 90);
        
        assertTrue(learnToEarn.courseCompleted(student, courseId));
        assertTrue(learnToEarn.courseCompleted(student2, courseId));
        
        assertEq(reputation.learnerScore(student), LEARNER_POINTS);
        assertEq(reputation.learnerScore(student2), LEARNER_POINTS);
        // Educator gets subscription points (10 * 2) + completion points (50 * 2)
        assertEq(reputation.educatorScore(educator), (10 * 2) + (EDUCATOR_POINTS * 2));
    }

    // Subscription expiry edge cases
    function testCanCompleteRightBeforeExpiry() public {
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Move to just before expiry (1 second before)
        uint64 expiry = subscription.getSubscription(student, educator);
        vm.warp(expiry - 1);
        
        // Should still be able to complete
        vm.prank(student);
        learnToEarn.completeCourse(courseId, 85);
        
        assertTrue(learnToEarn.courseCompleted(student, courseId));
    }

    function testCannotCompleteAfterExpiry() public {
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Move 1 second past expiry
        uint64 expiry = subscription.getSubscription(student, educator);
        vm.warp(expiry + 1);
        
        // Should not be able to complete
        vm.prank(student);
        vm.expectRevert(LearnToEarn.NoActiveSubscription.selector);
        learnToEarn.completeCourse(courseId, 85);
    }

    function testCanRenewAndCompleteAfterInitialExpiry() public {
        // Initial subscription
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Move past first expiry
        vm.warp(block.timestamp + 31 days);
        
        // Renew subscription
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Now should be able to complete
        vm.prank(student);
        learnToEarn.completeCourse(courseId, 85);
        
        assertTrue(learnToEarn.courseCompleted(student, courseId));
    }

    // Different educators tests
    function testStudentCanSubscribeToMultipleEducators() public {
        address educator2 = vm.addr(5);
        
        // Setup second educator
        vm.prank(educator2);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        vm.prank(educator2);
        uint256 courseId2 = courseRegistry.createCourse("ipfs://QmTest789");
        
        // Student subscribes to both
        vm.startPrank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        subscription.subscribe{value: MONTHLY_PRICE}(educator2, 1);
        
        // Complete courses from both educators
        learnToEarn.completeCourse(courseId, 85);
        learnToEarn.completeCourse(courseId2, 90);
        vm.stopPrank();
        
        // Check completions
        assertTrue(learnToEarn.courseCompleted(student, courseId));
        assertTrue(learnToEarn.courseCompleted(student, courseId2));
        
        // Both educators get reputation
        assertEq(reputation.educatorScore(educator), 10 + EDUCATOR_POINTS);
        assertEq(reputation.educatorScore(educator2), 10 + EDUCATOR_POINTS);
    }

    function testCannotCompleteCourseFromUnsubscribedEducator() public {
        address educator2 = vm.addr(5);
        
        // Setup second educator
        vm.prank(educator2);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        vm.prank(educator2);
        uint256 courseId2 = courseRegistry.createCourse("ipfs://QmTest789");
        
        // Student only subscribes to first educator
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Try to complete course from second educator
        vm.prank(student);
        vm.expectRevert(LearnToEarn.NoActiveSubscription.selector);
        learnToEarn.completeCourse(courseId2, 85);
    }

    // Score variations
    function testCompleteCourseWithPerfectScore() public {
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        vm.prank(student);
        learnToEarn.completeCourse(courseId, 100);
        
        assertTrue(learnToEarn.courseCompleted(student, courseId));
    }

    function testCompleteCourseWithVeryHighScore() public {
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        vm.prank(student);
        learnToEarn.completeCourse(courseId, 999);
        
        assertTrue(learnToEarn.courseCompleted(student, courseId));
    }

    // hasCompletedCourse helper tests
    function testHasCompletedCourseReturnsFalseInitially() public view {
        assertFalse(learnToEarn.hasCompletedCourse(student, courseId));
    }

    function testHasCompletedCourseReturnsTrueAfterCompletion() public {
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        vm.prank(student);
        learnToEarn.completeCourse(courseId, 85);
        
        assertTrue(learnToEarn.hasCompletedCourse(student, courseId));
    }

    // Integration test: Full flow
    function testFullLearnToEarnFlow() public {
        // 1. Educator sets up
        vm.prank(educator);
        uint256 courseId1 = courseRegistry.createCourse(METADATA_URI);
        
        // 2. Student subscribes
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE * 2}(educator, 2); // 2 months
        
        // 3. Student completes course
        vm.prank(student);
        learnToEarn.completeCourse(courseId1, 92);
        
        // 4. Verify everything
        assertTrue(subscription.isSubscribed(student, educator));
        assertTrue(learnToEarn.hasCompletedCourse(student, courseId1));
        assertEq(reputation.learnerScore(student), LEARNER_POINTS);
        assertEq(reputation.educatorScore(educator), 10 + EDUCATOR_POINTS);
        
        // 5. Time passes, student renews and completes another course
        vm.warp(block.timestamp + 35 days);
        
        // Still subscribed due to 2-month subscription
        assertTrue(subscription.isSubscribed(student, educator));
        
        // Educator creates another course
        vm.prank(educator);
        uint256 courseId2 = courseRegistry.createCourse("ipfs://QmTest999");
        
        // Student completes second course
        vm.prank(student);
        learnToEarn.completeCourse(courseId2, 88);
        
        // Final reputation check
        assertEq(reputation.learnerScore(student), LEARNER_POINTS * 2);
        assertEq(reputation.educatorScore(educator), 10 + (EDUCATOR_POINTS * 2));
    }
}

