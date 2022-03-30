const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

function verifyRoot(address, verAddress) {
  const leafNodes = address
    .map((i) => i.address)
    .map((addr) => keccak256(addr));

  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
  const claimingAddress = verAddress ? keccak256(verAddress) : leafNodes[2];
  const hexProof = merkleTree.getHexProof(claimingAddress);
  const rootHash = merkleTree.getRoot();

  console.log(
    "address eligible for whitelist",
    merkleTree.verify(hexProof, claimingAddress, rootHash)
  );
}

exports.verifyRoot = verifyRoot;
