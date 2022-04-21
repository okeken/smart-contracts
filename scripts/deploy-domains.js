async function main() {
  // We get the contract to deploy
  const Domains = await hre.ethers.getContractFactory("Domains");
  const domains = await Domains.deploy("okedomains");
  await domains.deployed();

  console.log("Domains deployed to:", domains.address);

  // We're passing in a second variable - value. This is the moneyyyyyyyyyy
  let txn = await domains.register("oke-test", {
    value: hre.ethers.utils.parseEther("0.001"),
  });
  await txn.wait();

  const address = await domains.getAddress("oke-test");
  console.log("Owner of domain oke-test", address);

  const balance = await hre.ethers.provider.getBalance(domains.address);
  console.log("Contract balance:", hre.ethers.utils.formatEther(balance));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
