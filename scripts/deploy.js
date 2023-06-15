// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  // registry, inventory, gold, item
  const registry = await hre.ethers.deployContract("ERC6551Registry");
  const inventory = await hre.ethers.deployContract(
    "TextQuestCharacterInventory"
  );
  const gold = await hre.ethers.deployContract("TextQuestGold");
  const item = await hre.ethers.deployContract("TextQuestItem");

  await Promise.all([
    registry.waitForDeployment(),
    inventory.waitForDeployment(),
    gold.waitForDeployment(),
    item.waitForDeployment(),
  ]);
  // character
  const character = await hre.ethers.deployContract("TextQuestCharacter", [
    registry.target,
    inventory.target,
    gold.target,
    item.target,
  ]);
  await character.waitForDeployment();

  console.log(`
  registry: ${registry.target},
  inventory: ${inventory.target},
  gold: ${gold.target},
  item: ${item.target},
  character: ${character.target},
  `);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
