// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/CourseRegistry.sol";

contract CourseRegistryTest is Test {
    CourseRegistry public registry;
    
    address public educator1;
    address public educator2;
    address public nonEducator;
    
    string constant METADATA_URI = "ipfs://QmTest123";
    string constant METADATA_URI_2 = "ipfs://QmTest456";

    event CourseCreated(uint256 indexed courseId, address indexed educator, string metadataURI);
    event CourseActiveChanged(uint256 indexed courseId, bool active);

    function setUp() public {
        educator1 = vm.addr(1);
        educator2 = vm.addr(2);
        nonEducator = vm.addr(3);
        
        registry = new CourseRegistry();
    }

    // Course creation tests
    function testCreateCourse() public {
        vm.prank(educator1);
        vm.expectEmit(true, true, false, true);
        emit CourseCreated(0, educator1, METADATA_URI);
        
        uint256 courseId = registry.createCourse(METADATA_URI);
        
        assertEq(courseId, 0);
        assertEq(registry.nextCourseId(), 1);
        
        (uint256 id, address educator, string memory uri, bool active) = registry.getCourse(courseId);
        assertEq(id, 0);
        assertEq(educator, educator1);
        assertEq(uri, METADATA_URI);
        assertTrue(active);
    }

    function testCreateMultipleCourses() public {
        vm.startPrank(educator1);
        uint256 courseId1 = registry.createCourse(METADATA_URI);
        uint256 courseId2 = registry.createCourse(METADATA_URI_2);
        vm.stopPrank();
        
        assertEq(courseId1, 0);
        assertEq(courseId2, 1);
        assertEq(registry.nextCourseId(), 2);
        
        (, address edu1,,) = registry.getCourse(courseId1);
        (, address edu2,,) = registry.getCourse(courseId2);
        assertEq(edu1, educator1);
        assertEq(edu2, educator1);
    }

    function testCreateCourseByDifferentEducators() public {
        vm.prank(educator1);
        uint256 courseId1 = registry.createCourse(METADATA_URI);
        
        vm.prank(educator2);
        uint256 courseId2 = registry.createCourse(METADATA_URI_2);
        
        assertEq(courseId1, 0);
        assertEq(courseId2, 1);
        
        (, address edu1,,) = registry.getCourse(courseId1);
        (, address edu2,,) = registry.getCourse(courseId2);
        assertEq(edu1, educator1);
        assertEq(edu2, educator2);
    }

    function testCreateCourseRevertsOnEmptyURI() public {
        vm.prank(educator1);
        vm.expectRevert(CourseRegistry.EmptyMetadataURI.selector);
        registry.createCourse("");
    }

    function testCreateCourseStartsActive() public {
        vm.prank(educator1);
        uint256 courseId = registry.createCourse(METADATA_URI);
        
        (,,, bool active) = registry.getCourse(courseId);
        assertTrue(active);
    }

    // Set course active tests
    function testSetCourseActiveToFalse() public {
        vm.prank(educator1);
        uint256 courseId = registry.createCourse(METADATA_URI);
        
        vm.prank(educator1);
        vm.expectEmit(true, false, false, true);
        emit CourseActiveChanged(courseId, false);
        registry.setCourseActive(courseId, false);
        
        (,,, bool active) = registry.getCourse(courseId);
        assertFalse(active);
    }

    function testSetCourseActiveToTrue() public {
        vm.startPrank(educator1);
        uint256 courseId = registry.createCourse(METADATA_URI);
        registry.setCourseActive(courseId, false);
        
        vm.expectEmit(true, false, false, true);
        emit CourseActiveChanged(courseId, true);
        registry.setCourseActive(courseId, true);
        vm.stopPrank();
        
        (,,, bool active) = registry.getCourse(courseId);
        assertTrue(active);
    }

    function testSetCourseActiveRevertsIfNotEducator() public {
        vm.prank(educator1);
        uint256 courseId = registry.createCourse(METADATA_URI);
        
        vm.prank(nonEducator);
        vm.expectRevert(CourseRegistry.NotCourseEducator.selector);
        registry.setCourseActive(courseId, false);
    }

    function testSetCourseActiveRevertsIfDifferentEducator() public {
        vm.prank(educator1);
        uint256 courseId = registry.createCourse(METADATA_URI);
        
        vm.prank(educator2);
        vm.expectRevert(CourseRegistry.NotCourseEducator.selector);
        registry.setCourseActive(courseId, false);
    }

    function testSetCourseActiveRevertsIfCourseDoesNotExist() public {
        vm.prank(educator1);
        vm.expectRevert(CourseRegistry.CourseDoesNotExist.selector);
        registry.setCourseActive(999, false);
    }

    // Get course tests
    function testGetCourseReturnsCorrectData() public {
        vm.prank(educator1);
        uint256 courseId = registry.createCourse(METADATA_URI);
        
        (uint256 id, address educator, string memory uri, bool active) = registry.getCourse(courseId);
        
        assertEq(id, courseId);
        assertEq(educator, educator1);
        assertEq(uri, METADATA_URI);
        assertTrue(active);
    }

    function testGetCourseRevertsIfDoesNotExist() public {
        vm.expectRevert(CourseRegistry.CourseDoesNotExist.selector);
        registry.getCourse(999);
    }

    // Storage mapping tests
    function testCoursesMapping() public {
        vm.prank(educator1);
        uint256 courseId = registry.createCourse(METADATA_URI);
        
        (uint256 id, address educator, string memory uri, bool active) = registry.courses(courseId);
        
        assertEq(id, courseId);
        assertEq(educator, educator1);
        assertEq(uri, METADATA_URI);
        assertTrue(active);
    }

    // Next course ID tests
    function testNextCourseIdIncrementsCorrectly() public {
        assertEq(registry.nextCourseId(), 0);
        
        vm.prank(educator1);
        registry.createCourse(METADATA_URI);
        assertEq(registry.nextCourseId(), 1);
        
        vm.prank(educator1);
        registry.createCourse(METADATA_URI_2);
        assertEq(registry.nextCourseId(), 2);
    }

    // Integration tests
    function testEducatorCanManageMultipleCourses() public {
        vm.startPrank(educator1);
        uint256 courseId1 = registry.createCourse(METADATA_URI);
        uint256 courseId2 = registry.createCourse(METADATA_URI_2);
        
        // Deactivate first course
        registry.setCourseActive(courseId1, false);
        vm.stopPrank();
        
        (,,, bool active1) = registry.getCourse(courseId1);
        (,,, bool active2) = registry.getCourse(courseId2);
        
        assertFalse(active1);
        assertTrue(active2);
    }

    function testCourseIdsPersistAcrossEducators() public {
        vm.prank(educator1);
        uint256 courseId1 = registry.createCourse(METADATA_URI);
        
        vm.prank(educator2);
        uint256 courseId2 = registry.createCourse(METADATA_URI_2);
        
        // Course IDs should be sequential regardless of educator
        assertEq(courseId1, 0);
        assertEq(courseId2, 1);
    }

    function testMetadataURICanBeRetrieved() public {
        vm.prank(educator1);
        uint256 courseId = registry.createCourse(METADATA_URI);
        
        (,, string memory retrievedUri,) = registry.getCourse(courseId);
        assertEq(retrievedUri, METADATA_URI);
    }
}

