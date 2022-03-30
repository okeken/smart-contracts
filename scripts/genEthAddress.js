var fs = require("fs");
var ethers = require("ethers");
var crypto = require("crypto");
const { getRoot } = require("./genMerkleeRoot");
const { verifyRoot } = require("./verifiyRoot");

function genAddress() {
  const id = crypto.randomBytes(32).toString("hex");
  const privateKey = "0x" + id;
  const wallet = new ethers.Wallet(privateKey);
  return {
    privateKey,
    wallet,
  };
}

const addressList = [];
const computeAddress = (length = 5) => {
  for (let i = 0; i < length; i++) {
    const { privateKey, wallet } = genAddress();
    addressList.push({
      address: wallet.address,
      privateKey,
    });
  }

  const addressString = JSON.stringify(addressList);

  fs.writeFile("addressList.json", addressString, function (err, result) {
    if (err) console.log("error", err);
  });
};

function main() {
  computeAddress();
  getRoot(addressList);
  verifyRoot(addressList); // "0x786BfF269d10812Ac61c0c197E3Fc4215cabc3d9" use an address as second argument to check for eligibility, it's  using the second gen address by default
}
main();
