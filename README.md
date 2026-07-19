# 🗳️ Decentralized Voting Smart Contract

A decentralized voting system built in Solidity that allows an owner to create elections, assign chairpersons, register candidates and voters, conduct secure voting, and declare winners.

## Features

* Create and manage elections
* Chairperson-based candidate registration
* Chairperson-based voter registration
* One vote per registered voter
* Time-based election lifecycle
* Winner declaration
* Custom errors for gas efficiency
* NatSpec documented
* Event logging for all state changes
* Comprehensive Foundry unit test suite
* Reusable `BaseTest` contract for shared test setup and helper functions

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

* **REGISTRATION** – Candidate and voter registration
* **ACTIVE** – Voting is open
* **ENDED** – Winner can be declared

## Main Functions

| Function              | Description                         |
| --------------------- | ----------------------------------- |
| `createElection()`    | Creates a new election              |
| `addCandidate()`      | Registers a candidate               |
| `addVoter()`          | Registers a voter                   |
| `castVote()`          | Casts a vote                        |
| `getWinner()`         | Declares and returns the winner     |
| `getElectionStatus()` | Returns the current election status |

## Testing

The project includes a complete unit test suite built with **Foundry**.

### Test Infrastructure

The reusable `BaseTest` contract provides:

* Shared contract deployment
* Election creation helpers
* Candidate registration helpers
* Voter registration helpers
* Time-warp utilities for registration, active voting, and ended election phases
* Reduced code duplication across test contracts

### Run Tests

```bash
forge test
```

Run tests with verbose output:

```bash
forge test -vvv
```

Generate a gas report:

```bash
forge test --gas-report
```

Generate a coverage report:

```bash
forge coverage
```

## Local Development

### Prerequisites

* Foundry
* Git

Install Foundry (if not already installed):

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Clone the Repository

```bash
git clone https://github.com/abhiblock-96/Voting-Contract.git
cd Voting-Contract
```

### Install Dependencies

```bash
forge install
```

### Build the Project

```bash
forge build
```

### Run the Test Suite

```bash
forge test
```

### Start a Local Anvil Node

```bash
anvil
```

## Deployment

Compile the contracts:

```bash
forge build
```

Deploy to a local Anvil node:

```bash
forge create src/VotingContract.sol:VotingContract \
    --private-key <PRIVATE_KEY> \
    --rpc-url http://127.0.0.1:8545
```

Deploy to a testnet:

```bash
forge create src/VotingContract.sol:VotingContract \
    --rpc-url <RPC_URL> \
    --private-key <PRIVATE_KEY>
```

## Security Features

* Owner-only election creation
* Chairperson-only candidate and voter registration
* One vote per voter
* Duplicate voter prevention
* Duplicate candidate symbol prevention
* Time-based access control
* Custom errors for efficient reverts

## Tech Stack

* Solidity `^0.8.4`
* Foundry
* Forge
* Anvil

## Future Improvements

* Batch voter registration
* Batch candidate registration
* Election cancellation
* Frontend integration
* DAO governance support

## License

This project is licensed under the MIT License.

## Author

**Abhishek Maurya**

GitHub: https://github.com/abhiblock-96
