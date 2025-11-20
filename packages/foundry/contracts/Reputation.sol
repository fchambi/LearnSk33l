//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Reputation
 * @notice Manages reputation scores for educators and learners in the Sk33L platform
 * @dev Only authorized contracts can modify reputation scores
 */
contract Reputation {
    // Custom errors for gas optimization
    error NotOwner();
    error NotAuthorized();
    error ZeroAddress();
    error InvalidAmount();

    // State variables
    address public immutable owner;
    
    /// @notice Reputation scores for educators
    mapping(address => uint256) public educatorScore;
    
    /// @notice Reputation scores for learners
    mapping(address => uint256) public learnerScore;
    
    /// @notice Contracts authorized to modify reputation scores
    mapping(address => bool) public authorized;

    // Events
    event AuthorizedUpdated(address indexed contractAddr, bool isAuthorized);
    event EducatorScoreIncreased(address indexed educator, uint256 amount, uint256 newScore);
    event LearnerScoreIncreased(address indexed learner, uint256 amount, uint256 newScore);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyAuthorized() {
        if (!authorized[msg.sender]) revert NotAuthorized();
        _;
    }

    /**
     * @notice Contract constructor
     * @param _owner Address that will own the contract
     */
    constructor(address _owner) {
        if (_owner == address(0)) revert ZeroAddress();
        owner = _owner;
    }

    /**
     * @notice Set authorization status for a contract
     * @param contractAddr Address of the contract to authorize/unauthorize
     * @param isAuth True to authorize, false to unauthorize
     */
    function setAuthorized(address contractAddr, bool isAuth) external onlyOwner {
        if (contractAddr == address(0)) revert ZeroAddress();
        authorized[contractAddr] = isAuth;
        emit AuthorizedUpdated(contractAddr, isAuth);
    }

    /**
     * @notice Increase an educator's reputation score
     * @param educator Address of the educator
     * @param amount Amount to increase the score by
     */
    function increaseEducatorScore(address educator, uint256 amount) external onlyAuthorized {
        if (educator == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidAmount();
        
        educatorScore[educator] += amount;
        emit EducatorScoreIncreased(educator, amount, educatorScore[educator]);
    }

    /**
     * @notice Increase a learner's reputation score
     * @param learner Address of the learner
     * @param amount Amount to increase the score by
     */
    function increaseLearnerScore(address learner, uint256 amount) external onlyAuthorized {
        if (learner == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidAmount();
        
        learnerScore[learner] += amount;
        emit LearnerScoreIncreased(learner, amount, learnerScore[learner]);
    }
}

