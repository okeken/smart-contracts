//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ERC20Token is ERC20, Ownable {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    }

    function mint(uint256 _amt) public onlyOwner {
        _mint(msg.sender, _amt * (10**18));
    }
}