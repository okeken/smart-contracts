const { expect } = require("chai");
const { ethers } = require("hardhat");

/**
 *
 * @param {*} amount: Number
 * @param {*} contract
 * @param {*} user
 * @returns
 */
const sentEth = async (amount, contract, user) => {
  if (typeof amount !== "number") throw new Error("enter valid value");
  const tx = await user.sendTransaction({
    to: contract.address,
    value: ethers.utils.parseEther(String(amount)), // Sends exactly 1.0 ether
  });
  return await tx.wait();
};

const getBalance = async (contract) => {
  const bal = await contract.getBalance();
  const balance = Number(bal.toString());
  return balance;
};

describe("EthWallet", async function () {
  let contract;
  let user1;
  let user2;
  let user3;

  beforeEach(async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    user1 = owner?.address;
    user2 = addr1;
    user3 = addr2;
    const EthWallet = await ethers.getContractFactory("EthWallet");
    contract = await EthWallet.deploy();
  });

  describe("deployment", async () => {
    it("deployer is the owner", async () => {
      const owner = await contract.getOwner();
      expect(owner).to.equal(user1);
    });
    it("deploys a contract", async () => {
      expect(contract.address).to.not.equal(0);
    });
  });

  describe("get contract balance", async () => {
    it("get contract balance", async () => {
      const balance = await contract.getBalance();
      expect(balance).to.equal(0);
    });
  });

  describe("transactions", async () => {
    it("deposit eth balance must be greater", async () => {
      await sentEth(1, contract, user2);
      const balance = await getBalance(contract);
      expect(balance).to.greaterThan(0);
    });

    it("amount deposited by user 2", async () => {
      await sentEth(1, contract, user2);
      const balance = await getBalance(contract);
      const user2Bal = await contract.connect(user2).getUserTotalDeposits();
      expect(Number(user2Bal.toString())).to.equal(balance);
    });

    it("withdraw all eth", async () => {
      await sentEth(3, contract, user2);
      const withdraw = await contract.withdrawAllEth();
      //const withdraw = await contract.connect(user3).withdrawAllEth();
      const balance = await getBalance(contract);
      expect(balance).to.equal(0);
    });

    it("total balance", async () => {
      await sentEth(2, contract, user2);
      await sentEth(5, contract, user3);
      const balance = await getBalance(contract);
      expect(balance).to.equal(7 * 10 ** 18);
    });

    it("withdraw an amount", async () => {
      await sentEth(10, contract, user2);
      await contract.withdrawEth(ethers.utils.parseEther("5"));
      const balance = await getBalance(contract);
      expect(balance).to.equal(5 * 10 ** 18);
    });
  });

  describe("get owner", async () => {
    it("get owner", async () => {
      const owner = await contract.getOwner();
      expect(owner).to.equal(user1);
    });
  });
});
