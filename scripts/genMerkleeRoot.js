const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

var fs = require("fs");
let whitelistAddresses;
function getAddress() {
  fs.readFile("addressList.json", function (err, data) {
    if (err) {
      return console.error(err);
    }

    whitelistAddresses = [...JSON.parse(data).map((i) => i.address)];
    //whitelistAddresses = info;
    console.log("Asynchronous read: " + whitelistAddresses);
  });
}

function getRoot(address) {
  // The leaves, merkleTree, and rootHas are all PRE-DETERMINED prior to whitelist claim
  console.log("white list from file", whitelistAddresses);

  const leafNodes = address
    .map((i) => i.address)
    .map((addr) => keccak256(addr));
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

// ***** ***** ***** ***** ***** ***** ***** ***** //

// CLIENT-SIDE: Use `msg.sender` address to query and API that returns the merkle proof
// required to derive the root hash of the Merkle Tree

// ✅ Positive verification of address
// const claimingAddress = leafNodes[6];
// ❌ Change this address to get a `false` verification
// const claimingAddress = keccak256("0X5B38DA6A701C568545DCFCB03FCB875F56BEDDD6");

// `getHexProof` returns the neighbour leaf and all parent nodes hashes that will
// be required to derive the Merkle Trees root hash.
// const hexProof = merkleTree.getHexProof(claimingAddress);
// console.log(hexProof);

// ✅ - ❌: Verify is claiming address is in the merkle tree or not.
// This would be implemented in your Solidity Smart Contract
// console.log(merkleTree.verify(hexProof, claimingAddress, rootHash));

exports.getRoot = getRoot;
