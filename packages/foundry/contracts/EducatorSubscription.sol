//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Reputation.sol";

/**
 * @title EducatorSubscription
 * @notice Manages monthly subscriptions to educators with platform fee
 * @dev Students subscribe to educators, payments are split: 2% platform, 98% educator
 */
contract EducatorSubscription {
    // Custom errors
    error NotOwner();
    error NotEducator();
    error PlanNotActive();
    error InvalidMonths();
    error InsufficientPayment();
    error TransferFailed();
    error ZeroAddress();
    error InvalidPrice();

    // Constants
    uint256 public constant PLATFORM_FEE_BPS = 200; // 2% in basis points (200/10000)
    uint256 public constant BPS_DENOMINATOR = 10000;
    uint256 public constant SUBSCRIPTION_DURATION = 30 days;
    uint256 public constant EDUCATOR_REPUTATION_POINTS = 10; // Points per new subscription

    // State variables
    address public immutable owner;
    Reputation public immutable reputation;
    uint256 public platformFeesCollected;

    /// @notice Subscription plan details for each educator
    struct SubscriptionPlan {
        uint256 monthlyPrice;
        bool active;
    }

    /// @notice Subscription details for each student-educator pair
    struct Subscription {
        uint64 expiry;
    }

    mapping(address => SubscriptionPlan) public plans;
    mapping(address => mapping(address => Subscription)) public subscriptions; // subscriptions[student][educator]

    // Events
    event PlanCreated(address indexed educator, uint256 monthlyPrice);
    event PlanPaused(address indexed educator);
    event PlanResumed(address indexed educator);
    event Subscribed(address indexed student, address indexed educator, uint8 months, uint64 expiry, uint256 amountPaid);
    event PlatformFeeCollected(uint256 amount);
    event PlatformFeesWithdrawn(address indexed owner, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /**
     * @notice Contract constructor
     * @param _owner Address that will own the contract and receive platform fees
     * @param _reputation Address of the Reputation contract
     */
    constructor(address _owner, address _reputation) {
        if (_owner == address(0) || _reputation == address(0)) revert ZeroAddress();
        owner = _owner;
        reputation = Reputation(_reputation);
    }

    /**
     * @notice Set the monthly subscription price for an educator
     * @param price Monthly price in wei
     */
    function setMonthlyPrice(uint256 price) external {
        if (price == 0) revert InvalidPrice();
        
        plans[msg.sender].monthlyPrice = price;
        plans[msg.sender].active = true;
        
        emit PlanCreated(msg.sender, price);
    }

    /**
     * @notice Pause the educator's subscription plan
     * @dev Only the educator can pause their own plan
     */
    function pausePlan() external {
        if (plans[msg.sender].monthlyPrice == 0) revert NotEducator();
        
        plans[msg.sender].active = false;
        emit PlanPaused(msg.sender);
    }

    /**
     * @notice Resume the educator's subscription plan
     * @dev Only the educator can resume their own plan
     */
    function resumePlan() external {
        if (plans[msg.sender].monthlyPrice == 0) revert NotEducator();
        
        plans[msg.sender].active = true;
        emit PlanResumed(msg.sender);
    }

    /**
     * @notice Subscribe to an educator's content
     * @param educator Address of the educator to subscribe to
     * @param months Number of months to subscribe for (1-12)
     */
    function subscribe(address educator, uint8 months) external payable {
        if (educator == address(0)) revert ZeroAddress();
        if (months == 0 || months > 12) revert InvalidMonths();
        
        SubscriptionPlan memory plan = plans[educator];
        if (!plan.active) revert PlanNotActive();
        
        // Calculate total cost
        uint256 totalCost = plan.monthlyPrice * months;
        if (msg.value < totalCost) revert InsufficientPayment();
        
        // Calculate fee split
        uint256 platformFee = (totalCost * PLATFORM_FEE_BPS) / BPS_DENOMINATOR;
        uint256 educatorPayment = totalCost - platformFee;
        
        // Track platform fees
        platformFeesCollected += platformFee;
        emit PlatformFeeCollected(platformFee);
        
        // Forward payment to educator
        (bool success,) = educator.call{value: educatorPayment}("");
        if (!success) revert TransferFailed();
        
        // Update subscription expiry
        Subscription storage sub = subscriptions[msg.sender][educator];
        uint64 currentExpiry = sub.expiry;
        uint64 baseTime = (currentExpiry > block.timestamp) ? currentExpiry : uint64(block.timestamp);
        uint64 newExpiry = baseTime + uint64(months * SUBSCRIPTION_DURATION);
        sub.expiry = newExpiry;
        
        // Increase educator reputation
        reputation.increaseEducatorScore(educator, EDUCATOR_REPUTATION_POINTS);
        
        emit Subscribed(msg.sender, educator, months, newExpiry, totalCost);
        
        // Refund excess payment
        if (msg.value > totalCost) {
            (bool refundSuccess,) = msg.sender.call{value: msg.value - totalCost}("");
            if (!refundSuccess) revert TransferFailed();
        }
    }

    /**
     * @notice Check if a student has an active subscription to an educator
     * @param student Address of the student
     * @param educator Address of the educator
     * @return bool True if subscription is active
     */
    function isSubscribed(address student, address educator) external view returns (bool) {
        return subscriptions[student][educator].expiry >= block.timestamp;
    }

    /**
     * @notice Withdraw accumulated platform fees
     * @dev Only owner can withdraw
     */
    function withdraw() external onlyOwner {
        uint256 amount = platformFeesCollected;
        platformFeesCollected = 0;
        
        (bool success,) = owner.call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit PlatformFeesWithdrawn(owner, amount);
    }

    /**
     * @notice Get subscription details for a student-educator pair
     * @param student Address of the student
     * @param educator Address of the educator
     * @return expiry Subscription expiry timestamp
     */
    function getSubscription(address student, address educator) external view returns (uint64 expiry) {
        return subscriptions[student][educator].expiry;
    }
}

