//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "src/VotingContract.sol";
import {BaseTest} from "test/BaseTest.t.sol";
/**
* @title VotingContractUnitTest
* @author Abhishek
* @notice Unit tests for the VotingContract.
* @dev Covers success scenarios, revert conditions, event emissions, and getter functions.
*/

contract VotingContractUnitTest is BaseTest {

    /// @notice Name used for creating test elections
    string electionName = "College Election";

    /// @notice Verifies that the contract owner is the deployer.
    function test_OwnerIsDeployer() public view {
        assertEq(votingContract.i_owner(), owner);
    }
    /// @notice Verifies that the owner can successfully create an election.
    function test_CreateElection_Succeeds() external {
        uint256 electionId = _createElection(electionName);

        uint256 updatedElectionId = votingContract.s_electionId();
        uint256[] memory ids = votingContract.getElectionId();
        assertEq(ids[0], electionId);

        (string memory name,,, address chairperson) = votingContract.s_electionFeed(ids[0]);
        assertEq(name, electionName);
        assertEq(chairperson, chairPerson);
        assertTrue(votingContract.s_electionIdExists(electionId));
        assertEq(updatedElectionId, 2);
    }

    /// @notice Ensures election creation reverts when called by a non-owner.
    function test_CreateElection_RevertsIfCallerIsNotOwner() public {
        vm.prank(stranger);
        vm.expectRevert(NotTheOwner.selector);
        votingContract.createElection(REG_WINDOW, VOTE_WINDOW, chairPerson, electionName);
    }

    /// @notice Ensures election creation reverts when the chairperson is the zero address.
    function test_CreateElection_RevertsIfChairPersonIsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(InvalidAddress.selector);
        votingContract.createElection(REG_WINDOW, VOTE_WINDOW, address(0), electionName);
    }

    /// @notice Ensures election creation reverts when the owner is assigned as chairperson.
    function test_CreateElection_RevertsIfChairPersonIsOwner() public {
        vm.prank(owner);
        vm.expectRevert(InvalidAddress.selector);
        votingContract.createElection(REG_WINDOW, VOTE_WINDOW, owner, electionName);
    }

    /// @notice Ensures election creation reverts when both time intervals are zero.
    function test_CreateElection_RevertsIfTimeIntervalsAreZero() public {
        vm.prank(owner);
        vm.expectRevert(IntervalsCannotBeZero.selector);
        votingContract.createElection(0, 0, chairPerson, electionName);
    }

    /// @notice Ensures election creation reverts when the voting interval is invalid.
    function test_CreateElection_RevertsIfVotingIntervalIsInvalid() public {
        vm.prank(owner);
        vm.expectRevert(InvalidTimeRange.selector);
        votingContract.createElection(REG_WINDOW, 10, chairPerson, electionName);
    }

    /// @notice Ensures election creation reverts when the election name is empty.
    function test_CreateElection_RevertsIfNameIsEmpty() public {
        vm.prank(owner);
        vm.expectRevert(EmptyStringNotAccepted.selector);
        votingContract.createElection(REG_WINDOW, VOTE_WINDOW, chairPerson, "");
    }

    /// @notice Verifies that creating an election emits the AddElection event.
    function test_CreateElection_EmitsAddElectionEvent() public {
        vm.expectEmit(true, true, false, false);
        emit AddElection(votingContract.s_electionId(), chairPerson);
        vm.prank(owner);
        _createElection(electionName);
    }

    /// @notice Ensures adding a candidate reverts when the election does not exist.
    function test_AddCandidate_RevertsIfElectionDoesNotExist() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        votingContract.addCandidate("Abhishek", "Lotus", electionId);
    }

    /// @notice Verifies that the chairperson can successfully add candidates.
    function test_AddCandidate_SucceedsWhenCalledByChairPerson() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId1 = _addCandidate("Bob", "Lotus", electionId);
        uint256 candidateId2 = _addCandidate("Anik", "Rose", electionId);

        uint256[] memory candidateIds = votingContract.getCandidateIds(electionId);
        assertEq(candidateIds.length, 2);
        assertEq(candidateIds[0], candidateId1);
        assertEq(candidateIds[1], candidateId2);

        (, string memory name,, uint256 voteCount) = votingContract.s_candidateFeed(candidateIds[0]);
        assertEq(name, "Bob");
        assert(voteCount == 0);
    }

    /// @notice Ensures adding a candidate reverts when called by a non-chairperson.
    function test_AddCandidate_RevertsIfCallerIsNotChairPerson() public {
        uint256 electionId = _createElection(electionName);
        vm.expectRevert(OnlyChairPersonCanAdd.selector);
        votingContract.addCandidate("Abhishek", "Lotus", electionId);
    }

    /// @notice Ensures adding a candidate reverts when the symbol already exists.
    function test_AddCandidate_RevertsIfSymbolAlreadyExists() public {
        uint256 electionId = _createElection(electionName);
        _addCandidate("Akash", "Lotus", 1);
        vm.prank(chairPerson);
        vm.expectRevert(SymbolAlreadyExists.selector);
        votingContract.addCandidate("Abhishek", "Lotus", electionId);
    }

    /// @notice Ensures adding a candidate reverts when the candidate name is empty.
    function test_AddCandidate_RevertsIfNameIsEmpty() public {
        uint256 electionId = _createElection(electionName);
        vm.prank(chairPerson);
        vm.expectRevert(EmptyStringNotAccepted.selector);
        votingContract.addCandidate("", "Lotus", electionId);
    }

    /// @notice Ensures adding a candidate reverts after the registration period ends.
    function test_AddCandidate_RevertsIfElectionIsNotInRegistration() public {
        vm.warp(100);
        uint256 electionId = _createElection(electionName);
        vm.warp(250);
        vm.prank(chairPerson);
        vm.expectRevert(ElectionNotInRegistration.selector);
        votingContract.addCandidate("Abhishek", "Lotus", electionId);
    }

    /// @notice Verifies that adding a candidate emits the AddCandidate event.
    function test_AddCandidate_EmitsAddCandidateEvent() public {
        uint256 electionId = _createElection(electionName);
        vm.expectEmit(true, true, false, false);
        emit AddCandidate(electionId, votingContract.s_candidateId());
        _addCandidate("Abhishek", "Lotus", electionId);
    }

    /// @notice Ensures adding a voter reverts when called by a non-chairperson.
    function test_AddVoter_RevertsIfCallerIsNotChairPerson() public {
        uint256 electionId = _createElection(electionName);
        vm.prank(stranger);
        vm.expectRevert(OnlyChairPersonCanAdd.selector);
        votingContract.addVoter(voter1, electionId);
    }

    /// @notice Verifies that the chairperson can successfully register a voter.
    function test_AddVoter_SucceedsWhenCalledByChairPerson() public {
        uint256 electionId = _createElection(electionName);
        _addVoter(voter1, electionId);

        address[] memory voterAddresses = votingContract.getRegisteredVoters(electionId);
        assertGt(voterAddresses.length, 0);
        assertEq(voterAddresses[0], voter1);
    }

    /// @notice Ensures adding a voter reverts when the election does not exist.
    function test_AddVoter_RevertsIfElectionDoesNotExist() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        _addVoter(voter1, electionId);
    }

    /// @notice Ensures adding a voter reverts when the voter address is the zero address.
    function test_AddVoter_RevertsIfVoterAddressIsZero() public {
        uint256 electionId = _createElection(electionName);
        vm.expectRevert(InvalidAddress.selector);
        _addVoter(address(0), electionId);
    }

    /// @notice Ensures adding a voter reverts when the voter is already registered.
    function test_AddVoter_RevertsIfVoterAlreadyRegistered() public {
        uint256 electionId = _createElection(electionName);
        _addVoter(voter1, electionId);
        vm.expectRevert(VoterAlreadyRegistered.selector);
        _addVoter(voter1, electionId);
    }

    /// @notice Ensures adding a voter reverts after the registration period ends.
    function test_AddVoter_RevertsIfElectionIsNotInRegistration() public {
        vm.warp(100);
        uint256 electionId = _createElection(electionName);
        _addCandidate("Abhishek", "Lotus", electionId);
        vm.warp(250);
        vm.prank(chairPerson);
        vm.expectRevert(ElectionNotInRegistration.selector);
        votingContract.addVoter(voter1, electionId);
    }

    /// @notice Verifies that registering a voter emits the AddVoter event.
    function test_AddVoter_EmitsAddVoterEvent() public {
        uint256 electionId = _createElection(electionName);
        vm.expectEmit(true, true, false, false);
        emit AddVoter(electionId, voter1);
        _addVoter(voter1, electionId);
    }

    /// @notice Ensures voting reverts when the election does not exist.
    function test_CastVote_RevertsIfElectionDoesNotExist() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        votingContract.castVote(electionId, 101);
    }

    /// @notice Ensures voting reverts when no candidates exist.
    function test_CastVote_RevertsIfNoCandidatesExist() public {
        uint256 electionId = _createElection(electionName);
        _warpToActive(electionId);
        uint256 candidateId = votingContract.s_candidateId();
        vm.expectRevert(NoElectionCandidateExists.selector);
        votingContract.castVote(electionId, candidateId);
    }

    /// @notice Ensures voting reverts when the candidate ID is invalid.
    function test_CastVote_RevertsIfCandidateIsInvalid() public {
        uint256 electionId = _createElection(electionName);
        _addCandidate("Abhishek", "Lotus", electionId);
        uint256 candidateId;
        _warpToActive(electionId);
        vm.expectRevert(InvalidCandidate.selector);
        votingContract.castVote(electionId, candidateId);
    }

    /// @notice Ensures unregistered voters cannot cast votes.
    function test_CastVote_RevertsIfVoterIsNotRegistered() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        _warpToActive(electionId);
        vm.prank(msg.sender);
        vm.expectRevert(VoterNotExists.selector);
        votingContract.castVote(electionId, candidateId);
    }

    /// @notice Ensures voting reverts before the voting period starts.
    function test_CastVote_RevertsBeforeVotingStarts() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        vm.expectRevert(ElectionNotActive.selector);
        votingContract.castVote(electionId, candidateId);
    }

    /// @notice Ensures a voter cannot vote more than once.
    function test_CastVote_RevertsIfVoterHasAlreadyVoted() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        _addVoter(voter1, electionId);
        _warpToActive(electionId);
        vm.prank(voter1);
        votingContract.castVote(electionId, candidateId);

        vm.prank(voter1);
        vm.expectRevert(AlreadyVoted.selector);
        votingContract.castVote(electionId, candidateId);
    }

    /// @notice Verifies that a registered voter can successfully cast a vote.
    function test_CastVote_SucceedsWhenVoterIsRegistered() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        _addVoter(voter1, electionId);
        _warpToActive(electionId);
        vm.prank(voter1);
        votingContract.castVote(electionId, candidateId);

        (,, bool hasVoted) = votingContract.s_voterFeed(electionId, voter1);
        assertEq(hasVoted, true);

        (,,, uint256 voteCount) = votingContract.s_candidateFeed(candidateId);
        assertEq(voteCount, 1);
    }

    /// @notice Ensures voting reverts after the voting period has ended.
    function test_CastVote_RevertsAfterVotingEnds() public {
        vm.warp(100);
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        vm.warp(1250);
        vm.expectRevert(ElectionNotActive.selector);
        votingContract.castVote(electionId, candidateId);
    }

    /// @notice Ensures voting reverts when no candidates exist even if voters are registered.
    function test_CastVote_RevertsIfNoCandidatesExistButVotersAreRegistered() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = votingContract.s_candidateId();
        _addVoter(voter1, electionId);
        _warpToActive(electionId);
        vm.prank(voter1);
        vm.expectRevert(NoElectionCandidateExists.selector);
        votingContract.castVote(electionId, candidateId);
    }

    /// @notice Verifies that casting a vote emits the CastVote event.
    function test_CastVote_EmitsCastVoteEvent() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        _addVoter(voter1, electionId);
        _warpToActive(electionId);
        vm.expectEmit(true, true, true, false);
        emit CastVote(electionId, candidateId, voter1);
        vm.prank(voter1);
        votingContract.castVote(electionId, candidateId);
    }

    /// @notice Ensures declaring a winner reverts when the election does not exist.
    function test_DeclareWinner_RevertsIfElectionDoesNotExist() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        votingContract.declareWinner(electionId);
    }

    /// @notice Ensures declaring a winner reverts when no candidates exist.
    function test_DeclareWinner_RevertsIfNoCandidatesExist() public {
        uint256 electionId = _createElection(electionName);
        vm.expectRevert(NoElectionCandidateExists.selector);
        votingContract.declareWinner(electionId);
    }

    /// @notice Ensures declaring a winner reverts before the election has ended.
    function test_DeclareWinner_RevertsIfElectionHasNotEnded() public {
        uint256 electionId = _createElection(electionName);
        _addCandidate("Abhishek", "Lotus", electionId);
        _warpToActive(electionId);
        vm.expectRevert(ElectionNotEnded.selector);
        votingContract.declareWinner(electionId);
    }

    /// @notice Ensures declaring a winner reverts when no votes have been cast.
    function test_DeclareWinner_RevertsIfNoVotesWereCast() public {
        uint256 electionId = _createElection(electionName);
        _addCandidate("Abhishek", "Lotus", electionId);
        _addVoter(voter1, electionId);
        _warpToEnd(electionId);
        vm.expectRevert(NoVotesCast.selector);
        votingContract.declareWinner(electionId);
    }

    /// @notice Verifies that the correct winner is declared after the election ends.
    function test_DeclareWinner_Succeeds() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        _addVoter(voter1, electionId);
        _warpToActive(electionId);
        vm.prank(voter1);
        votingContract.castVote(electionId, candidateId);
        _warpToEnd(electionId);
        uint256 winner = votingContract.declareWinner(electionId);

        assertEq(winner, 101);
    }

    /// @notice Verifies that the candidate with the highest votes wins.
    function test_DeclareWinner_SucceedsWithMultipleVoters() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId1 = _addCandidate("Abhishek", "Lotus", electionId);
        _addCandidate("Akash", "Rose", electionId);
        uint256 candidateId3 = _addCandidate("Anik", "Lily", electionId);
        _addVoter(voter1, electionId);
        _addVoter(voter2, electionId);
        _addVoter(voter3, electionId);
        _warpToActive(electionId);
        vm.prank(voter1);
        votingContract.castVote(electionId, candidateId1);
        vm.prank(voter2);
        votingContract.castVote(electionId, candidateId3);
        vm.prank(voter3);
        votingContract.castVote(electionId, candidateId3);
        _warpToEnd(electionId);
        uint256 winner = votingContract.declareWinner(electionId);
        assertEq(winner, candidateId3);
    }

    /// @notice Verifies that candidate vote counts determine the winner.
    function test_DeclareWinner_SucceedsWhenCandidateHasHighestVotes() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId1 = _addCandidate("Abhishek", "Lotus", electionId);
        _addCandidate("Akash", "Rose", electionId);
        uint256 candidateId3 = _addCandidate("Anik", "Lily", electionId);
        _addVoter(voter1, electionId);
        _addVoter(voter2, electionId);
        _addVoter(voter3, electionId);
        _warpToActive(electionId);
        vm.prank(voter1);
        votingContract.castVote(electionId, candidateId1);
        vm.prank(voter2);
        votingContract.castVote(electionId, candidateId3);
        vm.prank(voter3);
        votingContract.castVote(electionId, candidateId3);
        (,,, uint256 voteCount1) = votingContract.s_candidateFeed(candidateId1);
        (,,, uint256 voteCount3) = votingContract.s_candidateFeed(candidateId3);
        _warpToEnd(electionId);
        votingContract.declareWinner(electionId);
        assertGt(voteCount3, voteCount1);
    }

    /// @notice Ensures querying the election status reverts when the election does not exist.
    function test_GetElectionStatus_RevertsIfElectionDoesNotExist() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        votingContract.getElectionStatus(electionId);
    }

    /// @notice Verifies that the election status is REGISTRATION during the registration period.
    function test_GetElectionStatus_ReturnsRegistrationStatus() public {
        uint256 electionId = _createElection(electionName);
        _warpBeforeRegistrationEnds(electionId);
        VotingContract.ElectionStatus status = votingContract.getElectionStatus(electionId);

        assertEq(uint256(status), uint256(VotingContract.ElectionStatus.REGISTRATION));
    }

    /// @notice Verifies that the election status is ACTIVE during the voting period.
    function test_GetElectionStatus_ReturnsActiveStatus() public {
        uint256 electionId = _createElection(electionName);
        _warpToActive(electionId);
        VotingContract.ElectionStatus status = votingContract.getElectionStatus(electionId);

        assertEq(uint256(status), uint256(VotingContract.ElectionStatus.ACTIVE));
    }

    /// @notice Verifies that the election status is ENDED after the voting period.
    function test_GetElectionStatus_ReturnsEndedStatus() public {
        uint256 electionId = _createElection(electionName);
        _warpToEnd(electionId);
        VotingContract.ElectionStatus status = votingContract.getElectionStatus(electionId);

        assertEq(uint256(status), uint256(VotingContract.ElectionStatus.ENDED));
    }

    /// @notice Ensures retrieving candidate IDs reverts when the election does not exist.
    function test_GetCandidateIds_RevertsIfElectionDoesNotExist() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        votingContract.getCandidateIds(electionId);
    }

    /// @notice Verifies that all candidate IDs are returned for an existing election.
    function test_GetCandidateIds_ReturnsCandidateIds() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidate1 = _addCandidate("Abhishek", "Lotus", electionId);
        uint256 candidate2 = _addCandidate("Anik", "Rose", electionId);
        uint256[] memory candidates = votingContract.getCandidateIds(electionId);

        assert(candidates.length == 2);
        assertEq(candidates[0], candidate1);
        assertEq(candidates[1], candidate2);
    }

    /// @notice Ensures retrieving registered voters reverts when the election does not exist.
    function test_GetRegisteredVoters_RevertsIfElectionDoesNotExist() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        votingContract.getRegisteredVoters(electionId);
    }

    /// @notice Verifies that all registered voter addresses are returned for an existing election.
    function test_GetRegisteredVoters_ReturnsRegisteredVoters() public {
        uint256 electionId = _createElection(electionName);
        _addCandidate("Abhishek", "Lotus", electionId);
        _addVoter(voter1, electionId);
        _addVoter(voter2, electionId);
        _addVoter(voter3, electionId);
        address[] memory voterAddresses = votingContract.getRegisteredVoters(electionId);

        assert(voterAddresses.length == 3);
        assertEq(voterAddresses[0], voter1);
        assertEq(voterAddresses[2], voter3);
    }
}
