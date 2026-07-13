# Decentralized Voting Smart Contract

A decentralized voting system built in Solidity that allows an owner to create elections, assign chairpersons, register candidates and voters, conduct secure voting, and declare winners.

## Features

- Create and manage elections
- Chairperson-based candidate registration
- Chairperson-based voter registration
- One vote per registered voter
- Time-based election lifecycle
- Winner declaration
- Custom errors for gas efficiency
- NatSpec documented
- Event logging for all state changes
- Comprehensive Foundry test suite with reusable `BaseTest`

## Election Workflow

```text
Owner
   │
   ▼
Create Election
   │
   ▼
Assign Chairperson
   │
   ▼
Register Candidates
   │
   ▼
Register Voters
   │
   ▼
Voting Starts
   │
   ▼
Cast Votes
   │
   ▼
Voting Ends
   │
   ▼
Declare Winner
```

## Election Status

- **REGISTRATION** – Candidate and voter registration
- **ACTIVE** – Voting is open
- **ENDED** – Winner can be declared

## Main Functions

| Function | Description |
|----------|-------------|
| `createElection()` | Creates a new election |
| `addCandidate()` | Registers a candidate |
| `addVoter()` | Registers a voter |
| `castVote()` | Casts a vote |
| `getWinner()` | Declares and returns the winner |
| `getElectionStatus()` | Returns the current election status |

## Testing

The project includes a reusable **BaseTest** contract built with **Foundry** that provides:

- Shared contract deployment
- Election creation helpers
- Candidate registration helpers
- Voter registration helpers
- Time-warp utilities for testing registration, voting, and ended phases
- Reduced code duplication across test contracts

## Security Features

- Owner-only election creation
- Chairperson-only candidate and voter registration
- One vote per voter
- Duplicate voter prevention
- Duplicate candidate symbol prevention
- Time-based access control
- Custom errors for efficient reverts

## ⚙️ Tech Stack

- Solidity `^0.8.4`
- Foundry
- Forge
- Anvil

## Future Improvements

- Tie handling
- Batch voter registration
- Batch candidate registration
- Election cancellation
- Frontend integration
- DAO governance support

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

**Abhishek Maurya**

GitHub: https://github.com/abhiblock-96