const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const fs = require("fs");
const util = require("util");
const { readRoot, readAddress } = require("./utils");

const readFile = util.promisify(fs.readFile);

// async function readRoot() {
//   try {
//     const content = await readFile(".rootHash", "utf8");
//     return content;
//   } catch (e) {
//     console.error(e);
//   }
// }

// async function readAddress() {
//   try {
//     const content = await readFile("addressList.json", "utf8");
//     return JSON.parse(content);
//   } catch (e) {
//     console.error(e);
//   }
// }

async function verifyRoot(verAddress) {
  const rootHash = await readRoot();
  const addresses = await (await readAddress()).map((i) => i.address);
  const keccak256Address = addresses.map((i) => keccak256(i));
  // console.log(keccak256Address, "add check");

  const merkleTree = new MerkleTree(keccak256Address, keccak256, {
    sortPairs: true,
  });
  const claimingAddress1 = verAddress
    ? keccak256(verAddress)
    : keccak256Address[2];
  const hexProof = merkleTree.getHexProof(claimingAddress1);

  const isValid = merkleTree.verify(hexProof, claimingAddress1, rootHash);
  console.log(
    `${addresses[2]} => ${
      isValid ? "address eligible" : "address not eligible"
    }`
  );
}

exports.verifyRoot = verifyRoot;
// exports.readRoot = readRoot;
// exports.readAddress = readAddress;
//
