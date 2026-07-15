//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {console} from "forge-std/Console.sol";
import "src/VotingContract.sol";
import {BaseTest} from "test/BaseTest.t.sol";

contract VotingContractUnitTest is BaseTest {
    string electionName = "College Election";

    function testOwnerIsMsg_Sender() public view {
        assertEq(votingContract.i_owner(), owner);
    }

    function testCreateElection_PassesIfOwnerCall() external {
        uint256 electionId = _createElection(electionName);

        uint256 updatedElectionId = votingContract.s_electionId();
        uint256[] memory ids = votingContract.getElectionId();
        assertEq(ids[0], electionId);

        (string memory name,,, address chairperson) = votingContract.s_electionFeed(ids[0]);
        assertEq(name, electionName);
        assertEq(chairperson, chairPerson);
        assert(votingContract.s_electionIdExists(electionId) == true);
        assert(updatedElectionId == 2);
    }

    function test_CreateElection_RevertIfNotOwner() public {
        vm.prank(stranger);
        vm.expectRevert(NotTheOwner.selector);
        votingContract.createElection(REG_WINDOW, VOTE_WINDOW, chairPerson, electionName);
    }

    function test_CreateElection_RevertIfChairPersonZero() public {
        vm.prank(owner);
        vm.expectRevert(InvalidAddress.selector);
        votingContract.createElection(REG_WINDOW, VOTE_WINDOW, address(0), electionName);
    }

    function test_CreateElection_RevertIfChairPersonOwner() public {
        vm.prank(owner);
        vm.expectRevert(InvalidAddress.selector);
        votingContract.createElection(REG_WINDOW, VOTE_WINDOW, owner, electionName);
    }

    function test_CreateElection_RevertIfTimeZero() public {
        vm.prank(owner);
        vm.expectRevert(IntervalsCannotBeZero.selector);
        votingContract.createElection(0, 0, chairPerson, electionName);
    }

    function test_CreateElection_RevertIfEndTimeLesser() public {
        vm.prank(owner);
        vm.expectRevert(InvalidTimeRange.selector);
        votingContract.createElection(REG_WINDOW, 10, chairPerson, electionName);
    }

    function test_CreateElection_RevertIfNameEmpty() public {
        vm.prank(owner);
        vm.expectRevert(EmptyStringNotAccepted.selector);
        votingContract.createElection(REG_WINDOW, VOTE_WINDOW, chairPerson, "");
    }

    function test_CreateElection_LogEmit() public {
        vm.expectEmit(true, true, false, false);
        emit AddElection(votingContract.s_electionId(), chairPerson);
        vm.prank(owner);
        _createElection(electionName);
    }

    function testAddCandidate_RevertIfElectionNotFound() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        votingContract.addCandidate("Abhishek", "Lotus", electionId);
    }

    function testAddCandidate_PassesIfChairPerson() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId1 = _addCandidate("Bob", "Lotus", electionId);
        uint256 candidateId2 = _addCandidate("Anik", "Rose", electionId);

        uint256[] memory candidateIds = votingContract.getCandidateIds(electionId);
        assert(candidateIds.length == 2);
        assertEq(candidateIds[0], candidateId1);
        assertEq(candidateIds[1], candidateId2);

        (, string memory name,, uint256 voteCount) = votingContract.s_candidateFeed(candidateIds[0]);
        assertEq(name, "Bob");
        assert(voteCount == 0);
    }

    function testAddCandidate_RevertIfNotChairPerson() public {
        uint256 electionId = _createElection(electionName);
        vm.expectRevert(OnlyChairPersonCanAdd.selector);
        votingContract.addCandidate("Abhishek", "Lotus", electionId);
    }

    function testAddCandidate_RevertIfSymbolAlreadyExists() public {
        uint256 electionId = _createElection(electionName);
        _addCandidate("Akash", "Lotus", 1);
        vm.prank(chairPerson);
        vm.expectRevert(SymbolAlreadyExists.selector);
        votingContract.addCandidate("Abhishek", "Lotus", electionId);
    }

    function testAddCandidate_RevertIfEmptyString() public {
        uint256 electionId = _createElection(electionName);
        vm.prank(chairPerson);
        vm.expectRevert(EmptyStringNotAccepted.selector);
        votingContract.addCandidate("", "Lotus", electionId);
    }

    function testAddCandidate_RevertIfElectionNotInRegistration() public {
        vm.warp(100);
        uint256 electionId = _createElection(electionName);
        vm.warp(250);
        vm.prank(chairPerson);
        vm.expectRevert(ElectionNotInRegistration.selector);
        votingContract.addCandidate("Abhishek", "Lotus", electionId);
    }

    function testAddCandidate_LogEmit() public {
        uint256 electionId = _createElection(electionName);
        vm.expectEmit(true, true, false, false);
        emit AddCandidate(electionId, votingContract.s_candidateId());
        _addCandidate("Abhishek", "Lotus", electionId);
    }

    function testAddVoter_RevertIfNotChairPerson() public {
        uint256 electionId = _createElection(electionName);
        vm.prank(stranger);
        vm.expectRevert(OnlyChairPersonCanAdd.selector);
        votingContract.addVoter(voter1, electionId);
    }

    function testAddVoter_PassesIfChairPerson() public {
        uint256 electionId = _createElection(electionName);
        _addVoter(voter1, electionId);

        address[] memory voterAddresses = votingContract.getRegisteredVoters(electionId);
        assertGt(voterAddresses.length, 0);
        assertEq(voterAddresses[0], voter1);
    }

    function testAddVoter_RevertIfElectionNotFound() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        _addVoter(voter1, electionId);
    }

    function testAddVoter_RevertIfVoterAddressZero() public {
        uint256 electionId = _createElection(electionName);
        vm.expectRevert(InvalidAddress.selector);
        _addVoter(address(0), electionId);
    }

    function testAddVoter_RevertIfVoterAlreadyExists() public {
        uint256 electionId = _createElection(electionName);
        _addVoter(voter1, electionId);
        vm.expectRevert(VoterAlreadyRegistered.selector);
        _addVoter(voter1, electionId);
    }

    function testAddVoter_RevertIfElectionNotInRegistration() public {
        vm.warp(100);
        uint256 electionId = _createElection(electionName);
        _addCandidate("Abhishek", "Lotus", electionId);
        vm.warp(250);
        vm.prank(chairPerson);
        vm.expectRevert(ElectionNotInRegistration.selector);
        votingContract.addVoter(voter1, electionId);
    }

    function testAddVoter_LogEmit() public {
        uint256 electionId = _createElection(electionName);
        vm.expectEmit(true, true, false, false);
        emit AddVoter(electionId, voter1);
        _addVoter(voter1, electionId);
    }

    function testCastVote_RevertIfElectionNotFound() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        votingContract.castVote(electionId, 101);
    }

    function testCastVote_RevertIfNoCandidateExist() public {
        uint256 electionId = _createElection(electionName);
        _warpToActive(electionId);
        uint256 candidateId = votingContract.s_candidateId();
        vm.expectRevert(NoElectionCandidateExists.selector);
        votingContract.castVote(electionId, candidateId);
    }

    function testCaseVote_RevertIfCandidateIsInvalid() public {
        uint256 electionId = _createElection(electionName);
        _addCandidate("Abhishek", "Lotus", electionId);
        uint256 candidateId;
        _warpToActive(electionId);
        vm.expectRevert(InvalidCandidate.selector);
        votingContract.castVote(electionId, candidateId);
    }

    function testCaseVote_RevertIfVoterAddressNotRegistered() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        _warpToActive(electionId);
        vm.prank(msg.sender);
        vm.expectRevert(VoterNotExists.selector);
        votingContract.castVote(electionId, candidateId);
    }

    function testCaseVote_RevertIfElectionNotActive() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        vm.expectRevert(ElectionNotActive.selector);
        votingContract.castVote(electionId, candidateId);
    }

    function testCaseVote_RevertIfVoterAlreadyVoted() public {
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

    function testCastVote_PassIfRegisteredVoterCastVote() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        _addVoter(voter1, electionId);
        _warpToActive(electionId);
        vm.prank(voter1);
        votingContract.castVote(electionId, candidateId);

        (,, bool hasVoted) = votingContract.s_voterFeed(electionId, voter1);
        assert(hasVoted == true);

        (,,, uint256 voteCount) = votingContract.s_candidateFeed(candidateId);
        assert(voteCount == 1);
    }

    function testCastVote_RevertIfElectionNotActive() public {
        vm.warp(100);
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        vm.warp(1250);
        vm.expectRevert(ElectionNotActive.selector);
        votingContract.castVote(electionId, candidateId);
    }

    function testCastVote_emitLog() public {
        uint256 electionId = _createElection(electionName);
        uint256 candidateId = _addCandidate("Abhishek", "Lotus", electionId);
        _addVoter(voter1, electionId);
        _warpToActive(electionId);
        vm.expectEmit(true, true, true, false);
        emit CastVote(electionId, candidateId, voter1);
        vm.prank(voter1);
        votingContract.castVote(electionId, candidateId);
    }

    function testDeclareWinner_RevertIfElectionIdNotFound() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        votingContract.declareWinner(electionId);
    }

    function testDeclareWinner_RevertIfCandidateNotExist() public {
        uint256 electionId = _createElection(electionName);
        vm.expectRevert(NoElectionCandidateExists.selector);
        votingContract.declareWinner(electionId);
    }

    function testDeclareWinner_RevertIfElectionNotEnded() public {
        uint256 electionId = _createElection(electionName);
        _addCandidate("Abhishek", "Lotus", electionId);
        _warpToActive(electionId);
        vm.expectRevert(ElectionNotEnded.selector);
        votingContract.declareWinner(electionId);
    }

    function testDeclareWinner_RevertIfVoteCountZero() public {
        uint256 electionId = _createElection(electionName);
        _addCandidate("Abhishek", "Lotus", electionId);
        _addVoter(voter1, electionId);
        _warpToEnd(electionId);
        vm.expectRevert(NoVotesCast.selector);
        votingContract.declareWinner(electionId);
    }

    function testDeclareWinner_PassIfElectionEnded() public {
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

    function testElectionStatus_RevertIfElectionIdNotFound() public {
        uint256 electionId = votingContract.s_electionId();
        vm.expectRevert(ElectionIdNotFound.selector);
        votingContract.getElectionStatus(electionId);
    }

    function testElectionStatus_PassIfElectionInRegistration() public {
        uint256 electionId = _createElection(electionName);
        _warpBeforeRegistrationEnds(electionId);
        VotingContract.ElectionStatus status = votingContract.getElectionStatus(electionId);

        assertEq(uint256(status), uint256(VotingContract.ElectionStatus.REGISTRATION));
    }

    function testElectionStatus_PassIfElectionInActive() public {
        uint256 electionId = _createElection(electionName);
        _warpToActive(electionId);
        VotingContract.ElectionStatus status = votingContract.getElectionStatus(electionId);

        assertEq(uint256(status), uint256(VotingContract.ElectionStatus.ACTIVE));
    }

    function testElectionStatus_PassIfElectionEnded() public {
        uint256 electionId = _createElection(electionName);
        _warpToEnd(electionId);
        VotingContract.ElectionStatus status = votingContract.getElectionStatus(electionId);

        assertEq(uint256(status), uint256(VotingContract.ElectionStatus.ENDED));
    }
}
