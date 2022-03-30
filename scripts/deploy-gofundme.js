async function main() {
  // We get the contract to deploy
  const GoFundMe = await hre.ethers.getContractFactory("GoFundMe");
  const goFundMe = await GoFundMe.deploy();
  await goFundMe.deployed();
  console.log("GoFundMe deployed to:", goFundMe.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
