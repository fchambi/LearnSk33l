// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/EducatorSubscription.sol";
import "../contracts/Reputation.sol";

contract EducatorSubscriptionTest is Test {
    EducatorSubscription public subscription;
    Reputation public reputation;
    
    address public owner;
    address public educator;
    address public student;
    
    uint256 constant MONTHLY_PRICE = 0.1 ether;
    uint256 constant PLATFORM_FEE_BPS = 200; // 2%
    uint256 constant EDUCATOR_REPUTATION_POINTS = 10;

    event PlanCreated(address indexed educator, uint256 monthlyPrice);
    event PlanPaused(address indexed educator);
    event PlanResumed(address indexed educator);
    event Subscribed(address indexed student, address indexed educator, uint8 months, uint64 expiry, uint256 amountPaid);
    event PlatformFeeCollected(uint256 amount);

    function setUp() public {
        owner = vm.addr(1);
        educator = vm.addr(2);
        student = vm.addr(3);
        
        // Deploy Reputation first
        vm.prank(owner);
        reputation = new Reputation(owner);
        
        // Deploy EducatorSubscription
        vm.prank(owner);
        subscription = new EducatorSubscription(owner, address(reputation));
        
        // Authorize the subscription contract in reputation
        vm.prank(owner);
        reputation.setAuthorized(address(subscription), true);
        
        // Fund student
        vm.deal(student, 10 ether);
    }

    // Constructor tests
    function testConstructorSetsOwnerAndReputation() public view {
        assertEq(subscription.owner(), owner);
        assertEq(address(subscription.reputation()), address(reputation));
    }

    function testConstructorRevertsOnZeroOwner() public {
        vm.expectRevert(EducatorSubscription.ZeroAddress.selector);
        new EducatorSubscription(address(0), address(reputation));
    }

    function testConstructorRevertsOnZeroReputation() public {
        vm.expectRevert(EducatorSubscription.ZeroAddress.selector);
        new EducatorSubscription(owner, address(0));
    }

    // Set monthly price tests
    function testSetMonthlyPrice() public {
        vm.prank(educator);
        vm.expectEmit(true, false, false, true);
        emit PlanCreated(educator, MONTHLY_PRICE);
        
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        (uint256 price, bool active) = subscription.plans(educator);
        assertEq(price, MONTHLY_PRICE);
        assertTrue(active);
    }

    function testSetMonthlyPriceRevertsOnZero() public {
        vm.prank(educator);
        vm.expectRevert(EducatorSubscription.InvalidPrice.selector);
        subscription.setMonthlyPrice(0);
    }

    function testSetMonthlyPriceCanUpdatePrice() public {
        vm.startPrank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        subscription.setMonthlyPrice(MONTHLY_PRICE * 2);
        vm.stopPrank();
        
        (uint256 price,) = subscription.plans(educator);
        assertEq(price, MONTHLY_PRICE * 2);
    }

    // Pause/Resume plan tests
    function testPausePlan() public {
        vm.startPrank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        vm.expectEmit(true, false, false, false);
        emit PlanPaused(educator);
        subscription.pausePlan();
        vm.stopPrank();
        
        (, bool active) = subscription.plans(educator);
        assertFalse(active);
    }

    function testResumePlan() public {
        vm.startPrank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        subscription.pausePlan();
        
        vm.expectEmit(true, false, false, false);
        emit PlanResumed(educator);
        subscription.resumePlan();
        vm.stopPrank();
        
        (, bool active) = subscription.plans(educator);
        assertTrue(active);
    }

    function testPausePlanRevertsIfNoPlan() public {
        vm.prank(educator);
        vm.expectRevert(EducatorSubscription.NotEducator.selector);
        subscription.pausePlan();
    }

    // Subscribe tests
    function testSubscribeSingleMonth() public {
        // Educator sets up plan
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        uint256 educatorBalanceBefore = educator.balance;
        uint256 platformFeesBefore = subscription.platformFeesCollected();
        
        // Student subscribes
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        // Check subscription
        assertTrue(subscription.isSubscribed(student, educator));
        
        // Check payment split
        uint256 expectedPlatformFee = (MONTHLY_PRICE * PLATFORM_FEE_BPS) / 10000;
        uint256 expectedEducatorPayment = MONTHLY_PRICE - expectedPlatformFee;
        
        assertEq(subscription.platformFeesCollected(), platformFeesBefore + expectedPlatformFee);
        assertEq(educator.balance, educatorBalanceBefore + expectedEducatorPayment);
        
        // Check reputation increased
        assertEq(reputation.educatorScore(educator), EDUCATOR_REPUTATION_POINTS);
    }

    function testSubscribeMultipleMonths() public {
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        uint256 totalCost = MONTHLY_PRICE * 3;
        
        vm.prank(student);
        subscription.subscribe{value: totalCost}(educator, 3);
        
        assertTrue(subscription.isSubscribed(student, educator));
        
        // Check expiry is approximately 90 days from now
        uint64 expiry = subscription.getSubscription(student, educator);
        assertApproxEqAbs(expiry, uint64(block.timestamp + 90 days), 1);
    }

    function testSubscribeExtendsExistingSubscription() public {
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        // First subscription
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        uint64 firstExpiry = subscription.getSubscription(student, educator);
        
        // Move time forward 15 days
        vm.warp(block.timestamp + 15 days);
        
        // Renew subscription
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        uint64 secondExpiry = subscription.getSubscription(student, educator);
        
        // Second expiry should be 30 days after first expiry (not current time)
        assertEq(secondExpiry, firstExpiry + 30 days);
    }

    function testSubscribeRefundsExcessPayment() public {
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        uint256 studentBalanceBefore = student.balance;
        uint256 excessPayment = 0.5 ether;
        
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE + excessPayment}(educator, 1);
        
        uint256 studentBalanceAfter = student.balance;
        
        // Student should only lose MONTHLY_PRICE
        assertEq(studentBalanceBefore - studentBalanceAfter, MONTHLY_PRICE);
    }

    function testSubscribeRevertsIfPlanInactive() public {
        vm.startPrank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        subscription.pausePlan();
        vm.stopPrank();
        
        vm.prank(student);
        vm.expectRevert(EducatorSubscription.PlanNotActive.selector);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
    }

    function testSubscribeRevertsIfInsufficientPayment() public {
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        vm.prank(student);
        vm.expectRevert(EducatorSubscription.InsufficientPayment.selector);
        subscription.subscribe{value: MONTHLY_PRICE - 1}(educator, 1);
    }

    function testSubscribeRevertsOnZeroMonths() public {
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        vm.prank(student);
        vm.expectRevert(EducatorSubscription.InvalidMonths.selector);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 0);
    }

    function testSubscribeRevertsOnTooManyMonths() public {
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        vm.prank(student);
        vm.expectRevert(EducatorSubscription.InvalidMonths.selector);
        subscription.subscribe{value: MONTHLY_PRICE * 13}(educator, 13);
    }

    function testSubscribeRevertsOnZeroEducatorAddress() public {
        vm.prank(student);
        vm.expectRevert(EducatorSubscription.ZeroAddress.selector);
        subscription.subscribe{value: MONTHLY_PRICE}(address(0), 1);
    }

    // isSubscribed tests
    function testIsSubscribedReturnsFalseBeforeSubscription() public view {
        assertFalse(subscription.isSubscribed(student, educator));
    }

    function testIsSubscribedReturnsFalseAfterExpiry() public {
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        assertTrue(subscription.isSubscribed(student, educator));
        
        // Move past expiry
        vm.warp(block.timestamp + 31 days);
        
        assertFalse(subscription.isSubscribed(student, educator));
    }

    // Withdraw tests
    function testWithdrawPlatformFees() public {
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        // Multiple subscriptions
        address student2 = vm.addr(4);
        vm.deal(student2, 10 ether);
        
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        vm.prank(student2);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        uint256 expectedFees = (MONTHLY_PRICE * PLATFORM_FEE_BPS * 2) / 10000;
        assertEq(subscription.platformFeesCollected(), expectedFees);
        
        uint256 ownerBalanceBefore = owner.balance;
        
        vm.prank(owner);
        subscription.withdraw();
        
        assertEq(owner.balance, ownerBalanceBefore + expectedFees);
        assertEq(subscription.platformFeesCollected(), 0);
    }

    function testWithdrawRevertsIfNotOwner() public {
        vm.prank(student);
        vm.expectRevert(EducatorSubscription.NotOwner.selector);
        subscription.withdraw();
    }

    // Payment split verification
    function testPaymentSplitExactly2Percent() public {
        vm.prank(educator);
        subscription.setMonthlyPrice(1 ether);
        
        uint256 educatorBalanceBefore = educator.balance;
        
        vm.prank(student);
        subscription.subscribe{value: 1 ether}(educator, 1);
        
        uint256 platformFee = subscription.platformFeesCollected();
        uint256 educatorReceived = educator.balance - educatorBalanceBefore;
        
        // Platform should get 2% = 0.02 ether
        assertEq(platformFee, 0.02 ether);
        // Educator should get 98% = 0.98 ether
        assertEq(educatorReceived, 0.98 ether);
        // Total should equal payment
        assertEq(platformFee + educatorReceived, 1 ether);
    }

    // Integration test
    function testMultipleStudentsSubscribeToEducator() public {
        vm.prank(educator);
        subscription.setMonthlyPrice(MONTHLY_PRICE);
        
        address student2 = vm.addr(4);
        address student3 = vm.addr(5);
        vm.deal(student2, 10 ether);
        vm.deal(student3, 10 ether);
        
        vm.prank(student);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        vm.prank(student2);
        subscription.subscribe{value: MONTHLY_PRICE * 2}(educator, 2);
        
        vm.prank(student3);
        subscription.subscribe{value: MONTHLY_PRICE}(educator, 1);
        
        assertTrue(subscription.isSubscribed(student, educator));
        assertTrue(subscription.isSubscribed(student2, educator));
        assertTrue(subscription.isSubscribed(student3, educator));
        
        // Educator reputation increased for each subscription
        assertEq(reputation.educatorScore(educator), EDUCATOR_REPUTATION_POINTS * 3);
    }
}

