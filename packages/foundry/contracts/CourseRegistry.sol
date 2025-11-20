//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CourseRegistry
 * @notice Registry for courses created by educators
 * @dev Educators can create courses and manage their active status
 */
contract CourseRegistry {
    // Custom errors
    error NotCourseEducator();
    error CourseDoesNotExist();
    error EmptyMetadataURI();
    error ZeroAddress();

    /// @notice Course information
    struct Course {
        uint256 id;
        address educator;
        string metadataURI;
        bool active;
    }

    // State variables
    uint256 public nextCourseId;
    mapping(uint256 => Course) public courses;

    // Events
    event CourseCreated(uint256 indexed courseId, address indexed educator, string metadataURI);
    event CourseActiveChanged(uint256 indexed courseId, bool active);

    /**
     * @notice Create a new course
     * @param metadataURI IPFS URI or other link to course metadata
     * @return courseId The ID of the newly created course
     */
    function createCourse(string calldata metadataURI) external returns (uint256) {
        if (bytes(metadataURI).length == 0) revert EmptyMetadataURI();
        
        uint256 courseId = nextCourseId;
        nextCourseId++;
        
        courses[courseId] = Course({
            id: courseId,
            educator: msg.sender,
            metadataURI: metadataURI,
            active: true
        });
        
        emit CourseCreated(courseId, msg.sender, metadataURI);
        
        return courseId;
    }

    /**
     * @notice Set the active status of a course
     * @param courseId ID of the course to modify
     * @param active New active status
     */
    function setCourseActive(uint256 courseId, bool active) external {
        Course storage course = courses[courseId];
        
        if (course.educator == address(0)) revert CourseDoesNotExist();
        if (course.educator != msg.sender) revert NotCourseEducator();
        
        course.active = active;
        emit CourseActiveChanged(courseId, active);
    }

    /**
     * @notice Get course details
     * @param courseId ID of the course
     * @return id Course ID
     * @return educator Address of the course educator
     * @return metadataURI Course metadata URI
     * @return active Whether the course is active
     */
    function getCourse(uint256 courseId) external view returns (
        uint256 id,
        address educator,
        string memory metadataURI,
        bool active
    ) {
        Course memory course = courses[courseId];
        if (course.educator == address(0)) revert CourseDoesNotExist();
        
        return (course.id, course.educator, course.metadataURI, course.active);
    }
}

