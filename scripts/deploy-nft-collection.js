async function main() {
  // We get the contract to deploy
  const SolidNft = await hre.ethers.getContractFactory("SolidNft");
  const solidNft = await SolidNft.deploy("Solid Nft", "SNF");
  await solidNft.deployed();
  console.log("SolidNft deployed to:", solidNft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
