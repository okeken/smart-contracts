const fs = require("fs");
const util = require("util");

const readFile = util.promisify(fs.readFile);

async function readRoot() {
  try {
    const content = await readFile(".rootHash", "utf8");
    return content;
  } catch (e) {
    console.error(e);
  }
}

async function readAddress() {
  try {
    const content = await readFile("addressList.json", "utf8");
    return JSON.parse(content);
  } catch (e) {
    console.error(e);
  }
}

exports.readRoot = readRoot;
exports.readAddress = readAddress;
