async function main() {
  // We get the contract to deploy
  const Domains = await hre.ethers.getContractFactory("Domains");
  const domains = await Domains.deploy("oke");
  await domains.deployed();

  console.log("Domains deployed to:", domains.address);

  const txn = await domains.register("okeken", {
    value: hre.ethers.utils.parseEther("0.001"),
  });
  await txn.wait();

  const address = await domains.getAddress("okeken");
  console.log("Owner of domain okeken", address);

  const balance = await hre.ethers.provider.getBalance(domains.address);
  console.log("Contract balance:", hre.ethers.utils.formatEther(balance));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
