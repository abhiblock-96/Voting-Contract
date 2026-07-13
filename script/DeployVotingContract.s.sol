//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {VotingContract} from "src/VotingContract.sol";

contract DeployVotingContract is Script {
    function run() public returns (VotingContract) {
        VotingContract votingContract = new VotingContract();
        return votingContract;
    }
}
