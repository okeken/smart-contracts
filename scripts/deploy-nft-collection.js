async function main() {
  // We get the contract to deploy
  const SolidNft = await hre.ethers.getContractFactory("SolidNft");
  const solidNft = await SolidNft.deploy("Solid Nft", "SNF");
  await solidNft.deployed();
  console.log("SolidNft deployed to:", solidNft.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
