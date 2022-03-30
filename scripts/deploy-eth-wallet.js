async function main() {
  // We get the contract to deploy
  const EthWallet = await hre.ethers.getContractFactory("EthWallet");
  const ethWallet = await EthWallet.deploy();
  await ethWallet.deployed();
  console.log("EthWallet deployed to:", ethWallet.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
