//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ReEntrancy {
    modifier reEntrance() {
        bool running = false;
        require(running == false, "dont re entrancy");
        _;
        running = true;
    }
}
