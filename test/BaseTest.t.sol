//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import {Test} from "forge-std/Test.sol";
import {VotingContract} from "src/VotingContract.sol";

/// @title BaseTest
/// @author Abhishek Maurya
/// @notice Provides common setup and helper functions for VotingContract tests.
/// @dev Inherit from this contract to avoid duplicating deployment, election setup,
/// candidate registration, voter registration, and time manipulation logic.
contract BaseTest is Test {
    VotingContract internal votingContract;

    address internal owner = makeAddr("owner");
    address internal chairPerson = makeAddr("chairPerson");

    /* Random Voter Addresses, useful for test */
    address internal voter1 = makeAddr("voter1");
    address internal voter2 = makeAddr("voter2");
    address internal voter3 = makeAddr("voter3");
    address internal stranger = makeAddr("stranger");

    uint256 internal constant REG_WINDOW = 100; // seconds from "now" until voting starts
    uint256 internal constant VOTE_WINDOW = 1000; // seconds from "now" until voting ends

    /// @notice Deploys a fresh VotingContract instance before each test.
    /// @dev Deploys the contract using the predefined owner test account.
    function setUp() public {

        vm.prank(owner);
        votingContract = new VotingContract();
    }

    /// @notice Creates a new election.
    /// @param name Name of the election.
    /// @return electionId The ID assigned to the newly created election.
    /// @dev Assumes the caller is the contract owner.
    function _createElection(string memory name) internal returns (uint256 electionId) {
        electionId = votingContract.s_electionId();
        vm.prank(owner);
        votingContract.createElection(REG_WINDOW, VOTE_WINDOW, chairPerson, name);
    }

    /// @notice Adds a candidate to an election.
    /// @param name Name of the candidate.
    /// @param symbol Unique symbol representing the candidate.
    /// @param electionId ID of the election.
    /// @return candidateId The ID assigned to the newly added candidate.
    /// @dev Assumes the caller is the election's chairperson.
    function _addCandidate(string memory name, string memory symbol, uint256 electionId)
        internal
        returns (uint256 candidateId)
    {
        candidateId = votingContract.s_candidateId();
        vm.prank(chairPerson);
        votingContract.addCandidate(name, symbol, electionId);
    }

    /// @notice Registers a voter for an election.
    /// @param voterAdd Address of the voter.
    /// @param electionId ID of the election.
    /// @dev Assumes the caller is the election's chairperson.
    function _addVoter(address voterAdd, uint256 electionId) internal {
        vm.prank(chairPerson);
        votingContract.addVoter(voterAdd, electionId);
    }

    /// @notice Moves the block timestamp to just before voting starts.
    /// @param electionId ID of the election.
    /// @dev Useful for testing behavior during the registration period.
    function _warpBeforeRegistrationEnds(uint256 electionId) internal {
        (, uint256 startTime,,) = votingContract.s_electionFeed(electionId);
        vm.warp(startTime > 1 ? startTime - 1 : 0);
    }

    /// @notice Moves the block timestamp to the active voting period.
    /// @param electionId ID of the election.
    /// @dev Warps to one second after the election start time.
    function _warpToActive(uint256 electionId) internal {
        (, uint256 startTime,,) = votingContract.s_electionFeed(electionId);
        vm.warp(startTime + 1);
    }

    /// @notice Moves the block timestamp to after the election has ended.
    /// @param electionId ID of the election.
    /// @dev Warps to one second after the election end time.
    function _warpToEnd(uint256 electionId) internal {
        (,, uint256 endTime,) = votingContract.s_electionFeed(electionId);
        vm.warp(endTime + 1);
    }
}
