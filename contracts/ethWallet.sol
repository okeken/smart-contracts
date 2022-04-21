//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./utils/reEntrancy.sol";

contract EthWallet is ReEntrancy {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    //events
    event EthDeposited(bool success, address sender, uint256 amount);
    event EthWithdrawn(bool success, uint256 amount);

    //Mappings
    mapping(address => uint256) public balances;

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit EthDeposited(true, msg.sender, msg.value);
    }

    function depositEth() public payable returns (uint256) {
        (bool sent, ) = owner.call{value: msg.value}("");
        require(sent, "Failed to send ether");
        balances[msg.sender] += msg.value;
        emit EthDeposited(true, msg.sender, msg.value);
        return msg.value;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function withdrawAllEth() public onlyOwner returns (bool) {
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw ether");
        emit EthWithdrawn(true, address(this).balance);
        return sent;
    }

    function withdrawEth(uint256 _amount) public onlyOwner returns (bool) {
        (bool sent, ) = owner.call{value: _amount}("");
        require(sent, "Failed to withdraw ether");
        emit EthWithdrawn(true, _amount);
        return sent;
    }

    function getUserTotalDeposits() public view returns (uint256) {
        return balances[msg.sender];
    }
}
