//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./CourseRegistry.sol";
import "./EducatorSubscription.sol";
import "./Reputation.sol";

/**
 * @title LearnToEarn
 * @notice Manages course completions and distributes reputation rewards
 * @dev Students must have active subscriptions to complete courses and earn rewards
 */
contract LearnToEarn {
    // Custom errors
    error CourseNotActive();
    error NoActiveSubscription();
    error ScoreTooLow();
    error AlreadyCompleted();
    error ZeroAddress();

    // Constants
    uint256 public constant MIN_SCORE = 70;
    uint256 public constant LEARNER_POINTS = 100;
    uint256 public constant EDUCATOR_POINTS = 50;

    // Contract references
    CourseRegistry public immutable courseRegistry;
    EducatorSubscription public immutable educatorSubscription;
    Reputation public immutable reputation;

    // State variables
    /// @notice Track course completion for each student
    mapping(address => mapping(uint256 => bool)) public courseCompleted;

    // Events
    event CourseCompleted(
        address indexed student,
        address indexed educator,
        uint256 indexed courseId,
        uint256 score,
        uint256 learnerPoints,
        uint256 educatorPoints
    );

    /**
     * @notice Contract constructor
     * @param _courseRegistry Address of the CourseRegistry contract
     * @param _educatorSubscription Address of the EducatorSubscription contract
     * @param _reputation Address of the Reputation contract
     */
    constructor(
        address _courseRegistry,
        address _educatorSubscription,
        address _reputation
    ) {
        if (
            _courseRegistry == address(0) ||
            _educatorSubscription == address(0) ||
            _reputation == address(0)
        ) revert ZeroAddress();
        
        courseRegistry = CourseRegistry(_courseRegistry);
        educatorSubscription = EducatorSubscription(_educatorSubscription);
        reputation = Reputation(_reputation);
    }

    /**
     * @notice Complete a course and earn reputation rewards
     * @param courseId ID of the course to complete
     * @param score Score achieved in the course (must be >= MIN_SCORE)
     */
    function completeCourse(uint256 courseId, uint256 score) external {
        // Get course details
        (, address educator, , bool active) = courseRegistry.getCourse(courseId);
        
        // Validate course is active
        if (!active) revert CourseNotActive();
        
        // Validate student has active subscription
        if (!educatorSubscription.isSubscribed(msg.sender, educator)) {
            revert NoActiveSubscription();
        }
        
        // Validate score meets minimum requirement
        if (score < MIN_SCORE) revert ScoreTooLow();
        
        // Check if already completed
        if (courseCompleted[msg.sender][courseId]) revert AlreadyCompleted();
        
        // Mark course as completed
        courseCompleted[msg.sender][courseId] = true;
        
        // Increase reputation scores
        reputation.increaseLearnerScore(msg.sender, LEARNER_POINTS);
        reputation.increaseEducatorScore(educator, EDUCATOR_POINTS);
        
        emit CourseCompleted(
            msg.sender,
            educator,
            courseId,
            score,
            LEARNER_POINTS,
            EDUCATOR_POINTS
        );
    }

    /**
     * @notice Check if a student has completed a course
     * @param student Address of the student
     * @param courseId ID of the course
     * @return bool True if the course has been completed
     */
    function hasCompletedCourse(address student, uint256 courseId) external view returns (bool) {
        return courseCompleted[student][courseId];
    }
}

