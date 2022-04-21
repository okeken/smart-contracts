const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
var fs = require("fs");
const { readAddress } = require("./utils");
// const { readAddress } = require("./verifiyRoot.js");

async function getRoot(address) {
  // The leaves, merkleTree, and rootHas are all PRE-DETERMINED prior to whitelist claim
  // const qw = await readAddress();
  const qw = await readAddress();
  console.log(qw, "qw check");
  const leafNodes = qw.map((i) => i.address).map((addr) => keccak256(addr));
  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

  // 4. Get root hash of the `merkleeTree` in hexadecimal format (0x)
  // Print out the Entire Merkle Tree.
  const rootHash = merkleTree.getRoot();
  console.log("Whitelist Merkle Tree\n", merkleTree.toString());
  console.log("Root Hash: ", rootHash.toString("hex"));

  fs.writeFile(
    ".rootHash",
    `0x${rootHash.toString("hex")}`,
    function (err, result) {
      if (err) console.log("error", err);
    }
  );
}

exports.getRoot = getRoot;
