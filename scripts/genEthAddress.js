var fs = require("fs");
var ethers = require("ethers");
var crypto = require("crypto");
const { getRoot } = require("./genMerkleeRoot");
const { verifyRoot, readAddress } = require("./verifiyRoot");

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
let sec = "";
const computeAddress = (length = 10000) => {
  for (let i = 0; i < length; i++) {
    const { privateKey, wallet } = genAddress();
    sec += `${wallet.address},`;
    addressList.push({
      address: wallet.address,
      privateKey,
    });
  }

  console.log(sec);

  const addressString = JSON.stringify(addressList);
  const address = JSON.stringify(sec);

  fs.writeFile("addressList.json", addressString, function (err, result) {
    if (err) console.log("error", err);
  });
  fs.writeFile("address.js", address, function (err, result) {
    if (err) console.log("error", err);
  });
};

async function main() {
  computeAddress();
  getRoot(addressList);
  verifyRoot(); // "0x786BfF269d10812Ac61c0c197E3Fc4215cabc3d9" as an argument to check for eligibility, it's  using the second gen address by default
}
main();
