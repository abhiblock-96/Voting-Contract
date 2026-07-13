// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* Error Declaration */

error NotTheOwner();
error InvalidAddress();
error IntervalsCannotBeZero();
error OnlyChairPersonCanAdd();
error ElectionIdNotFound();
error SymbolAlreadyExists();
error VoterAlreadyRegistered();
error VoterNotExists();
error AlreadyVoted();
error InvalidCandidate();
error InvalidTimeRange();
error ElectionNotInRegistration();
error ElectionNotActive();
error ElectionNotEnded();
error NoElectionCandidateExists();
error NoVotesCast();
error EmptyStringNotAccepted();

/* Event Declaration */

/// @notice Emitted when a new election is created.
/// @param electionId Unique identifier of the election.
/// @param chairPerson Address assigned as the election chairperson.
event AddElection(uint256 indexed electionId, address indexed chairPerson);

/// @notice Emitted when a new candidate is added to an election.
/// @param electionId Unique identifier of the election.
/// @param candidateId Unique identifier assigned to the candidate.
event AddCandidate(uint256 indexed electionId, uint256 indexed candidateId);

/// @notice Emitted when a voter is registered for an election.
/// @param electionId Unique identifier of the election.
/// @param voter Address of the registered voter.
event AddVoter(uint256 indexed electionId, address indexed voter);

/// @notice Emitted when a voter casts a vote.
/// @param electionId Unique identifier of the election.
/// @param candidateId Unique identifier of the selected candidate.
/// @param voter Address of the voter who cast the vote.
event CastVote(uint256 indexed electionId, uint256 indexed candidateId, address indexed voter);

/**
 * @title Decentralized Voting Contract
 * @author Abhishek Maurya
 * @notice A decentralized voting system for creating and managing elections
 * @dev Elections are identified by unique election IDs
 * @dev Candidate IDs are globally unique across all elections.
 * @dev Each voter may register and vote independently in multiple elections.
 */

contract VotingContract {
    /* TYPE DECLARATION */

    /// @notice Stores metadata for an election.
    struct ElectionDetails {
        string name;
        uint256 startTime;
        uint256 endTime;
        address chairPerson;
    }

    /// @notice Stores candidate information for an election.
    struct CandidateDetails {
        uint256 electionId;
        string name;
        string symbol;
        uint256 voteCount;
    }

    /// @notice Stores voter information for a specific election.
    struct VoterDetails {
        address voterAddress;
        uint256 electionId;
        bool hasVoted;
    }

    /// @notice Represents the current state of an election.
    enum ElectionStatus {
        REGISTRATION,
        ACTIVE,
        ENDED
    }

    /* STATE VARIABLE DECLARATION */

    /// @notice This maps the ElectionId to its Election Data.
    mapping(uint256 => ElectionDetails) public s_electionFeed;

    /// @notice This maps the ElectionId to its list of CandidateIds for better lookup.
    mapping(uint256 => uint256[]) public s_electionCandidates;

    /// @notice This maps CandidateId to its Candidate Data.
    mapping(uint256 => CandidateDetails) public s_candidateFeed;

    /// @notice Maps an election ID and voter address to voter details.
    /// @dev Allows the same address to participate in multiple elections independently.
    mapping(uint256 => mapping(address => VoterDetails)) public s_voterFeed;

    /// @notice Maps an election ID to the list of registered voter addresses.
    mapping(uint256 => address[]) public s_electionVoters;

    /// @notice Maps an election ID and candidate symbol to a boolean indicating whether the symbol already exists.
    mapping(uint256 => mapping(string => bool)) public s_candidateSymbolExists;

    /// @notice Tracks whether an election ID exists.
    mapping(uint256 => bool) public s_electionIdExists;

    /// @notice Tracks whether a voter is registered for an election.
    mapping(uint256 => mapping(address => bool)) public s_voterExists;

    /// @notice Tracks whether a candidate belongs to an election.
    mapping(uint256 => mapping(uint256 => bool)) public s_candidateExists;

    /// @notice Contract owner.
    address public immutable i_owner;

    /// @notice Stores all election IDs.
    uint256[] public s_electionIdList;

    /// @notice Auto-incrementing election ID.
    uint256 public s_electionId = 1;

    /// @notice Auto-incrementing candidate ID.
    uint256 public s_candidateId = 101;

    /* Constructor Declaration */

    /// @notice Initializes the contract owner.
    constructor() {
        i_owner = msg.sender;
    }

    /// @dev Restricts access to the contract owner.
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotTheOwner();
        _;
    }

    /* Function Declaration */

    /// @notice Returns the current Election Status.
    /// @param electionId of the Election.
    /// @return status Current election status.
    function getElectionStatus(uint256 electionId) public view returns (ElectionStatus) {
        if (!s_electionIdExists[electionId]) revert ElectionIdNotFound();

        ElectionDetails storage election = s_electionFeed[electionId];

        if (block.timestamp < election.startTime) {
            return ElectionStatus.REGISTRATION;
        } else if (block.timestamp < election.endTime) {
            return ElectionStatus.ACTIVE;
        } else {
            return ElectionStatus.ENDED;
        }
    }

    /// @notice Creates a new election.
    /// @param startTime Seconds from now until voting starts.
    /// @param endTime Seconds from now until voting ends.
    /// @param _chairPerson Address managing the election.
    /// @param name Name of the election.
    function createElection(uint256 startTime, uint256 endTime, address _chairPerson, string memory name)
        external
        onlyOwner
    {
        if (_chairPerson == address(0) || _chairPerson == i_owner) {
            revert InvalidAddress();
        }

        if (startTime == 0 || endTime == 0) {
            revert IntervalsCannotBeZero();
        }

        if (endTime <= startTime) {
            revert InvalidTimeRange();
        }
        if (bytes(name).length == 0) revert EmptyStringNotAccepted();

        // This adds the ElectionId to the ElectionId list.
        s_electionIdList.push(s_electionId);

        //  This updates the address existence to true.
        s_electionIdExists[s_electionId] = true;

        // This adds the election data to ElectionId.
        s_electionFeed[s_electionId] = ElectionDetails({
            name: name,
            startTime: block.timestamp + startTime,
            endTime: block.timestamp + endTime,
            chairPerson: _chairPerson
        });

        emit AddElection(s_electionId, _chairPerson);

        unchecked {
            s_electionId++;
        }
    }

    /// @notice Adds a candidate to an election.
    /// @param name Name of the candidate.
    /// @param symbol Symbol of the Candidate.
    /// @param electionId Unique identifier of the election.
    function addCandidate(string calldata name, string calldata symbol, uint256 electionId) external {
        if (!s_electionIdExists[electionId]) revert ElectionIdNotFound();
        if (msg.sender != s_electionFeed[electionId].chairPerson) revert OnlyChairPersonCanAdd();
        if (s_candidateSymbolExists[electionId][symbol]) revert SymbolAlreadyExists();
        if (getElectionStatus(electionId) != ElectionStatus.REGISTRATION) {
            revert ElectionNotInRegistration();
        }
        if (bytes(name).length == 0 || bytes(symbol).length == 0) revert EmptyStringNotAccepted();

        // It stores a list of Candidate Ids mapped to Election Id.
        s_electionCandidates[electionId].push(s_candidateId);

        // It maps Candidate Id to Candidate Data.
        s_candidateFeed[s_candidateId] =
            CandidateDetails({electionId: electionId, name: name, symbol: symbol, voteCount: 0});
        s_candidateSymbolExists[electionId][symbol] = true;
        s_candidateExists[electionId][s_candidateId] = true;

        emit AddCandidate(electionId, s_candidateId);

        unchecked {
            s_candidateId++;
        }
    }

    /// @notice Registers a voter for an election.
    /// @param voterAdd Address of the Voter.
    /// @param electionId Unique identifier of the election.
    function addVoter(address voterAdd, uint256 electionId) external {
        if (!s_electionIdExists[electionId]) revert ElectionIdNotFound();
        if (msg.sender != s_electionFeed[electionId].chairPerson) revert OnlyChairPersonCanAdd();
        if (voterAdd == address(0)) revert InvalidAddress();
        if (s_voterExists[electionId][voterAdd]) revert VoterAlreadyRegistered();
        if (getElectionStatus(electionId) != ElectionStatus.REGISTRATION) {
            revert ElectionNotInRegistration();
        }

        // It maps Election Id to list of Voter Addresses.
        s_electionVoters[electionId].push(voterAdd);

        // It maps Election Id to Voter Id which stores Voter Details.
        s_voterFeed[electionId][voterAdd] =
            VoterDetails({voterAddress: voterAdd, electionId: electionId, hasVoted: false});
        s_voterExists[electionId][voterAdd] = true;

        emit AddVoter(electionId, voterAdd);
    }

    /// @notice Casts a vote for a candidate.
    /// @param electionId Unique identifier of the election.
    /// @param candidateId Unique identifier of the candidate within the system.
    function castVote(uint256 electionId, uint256 candidateId) external {
        if (!s_electionIdExists[electionId]) revert ElectionIdNotFound();
        if (getElectionStatus(electionId) != ElectionStatus.ACTIVE) {
            revert ElectionNotActive();
        }
        if (s_electionCandidates[electionId].length == 0) revert NoElectionCandidateExists();
        if (!s_candidateExists[electionId][candidateId]) revert InvalidCandidate();
        if (!s_voterExists[electionId][msg.sender]) revert VoterNotExists();
        if (s_voterFeed[electionId][msg.sender].hasVoted) revert AlreadyVoted();

        // fetching the Vote Count from each Candidate data.
        s_candidateFeed[candidateId].voteCount += 1;

        // Updating the Voter address who voted successfully.
        s_voterFeed[electionId][msg.sender].hasVoted = true;

        emit CastVote(electionId, candidateId, msg.sender);
    }

    /// @notice Returns and declares the winning candidate of an election.
    /// @param electionId Unique identifier of the election.
    /// @return winnerId Candidate ID with highest votes.
    function declareWinner(uint256 electionId) external view returns (uint256) {
        if (!s_electionIdExists[electionId]) revert ElectionIdNotFound();
        if (s_electionCandidates[electionId].length == 0) revert NoElectionCandidateExists();
        if (getElectionStatus(electionId) != ElectionStatus.ENDED) {
            revert ElectionNotEnded();
        }
        uint256 highestVoteCount;
        uint256 winnerId;

        // Getting the Candidate Id who has highest Vote.
        for (uint256 i = 0; i < s_electionCandidates[electionId].length; i++) {
            uint256 candidateId = s_electionCandidates[electionId][i];
            CandidateDetails storage candidateData = s_candidateFeed[candidateId];
            if (candidateData.voteCount > highestVoteCount) {
                highestVoteCount = candidateData.voteCount;
                winnerId = candidateId;
            }
        }
        if (highestVoteCount == 0) revert NoVotesCast();
        return (winnerId);
    }

    /// @notice Returns all created election IDs.
    /// @return electionIds Array of election IDs.
    function getElectionId() external view returns (uint256[] memory) {
        return s_electionIdList;
    }

    /// @notice Returns the candidate IDs for an election.
    /// @param electionId Unique identifier of the election.
    /// @return Candidate IDs belonging to the election.
    function getCandidateIds(uint256 electionId) external view returns (uint256[] memory) {
        if (!s_electionIdExists[electionId]) revert ElectionIdNotFound();
        return s_electionCandidates[electionId];
    }

    /// @notice Returns the registered voter addresses for an election.
    /// @param electionId Unique identifier of the election.
    /// @return Registered voter addresses.
    function getRegisteredVoters(uint256 electionId) external view returns (address[] memory) {
        if (!s_electionIdExists[electionId]) revert ElectionIdNotFound();
        return s_electionVoters[electionId];
    }
}
