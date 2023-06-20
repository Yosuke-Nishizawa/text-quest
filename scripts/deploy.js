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
  // itemShop
  const itemShop = await hre.ethers.deployContract("TextQuestItemShop", [
    item.target,
    gold.target,
  ]);
  // character
  const character = await hre.ethers.deployContract("TextQuestCharacter", [
    registry.target,
    inventory.target,
    gold.target,
    item.target,
  ]);
  await Promise.all([
    itemShop.waitForDeployment(),
    character.waitForDeployment(),
  ]);

  const contractAddresses = {
    registry: registry.target,
    inventory: inventory.target,
    gold: gold.target,
    item: item.target,
    itemShop: itemShop.target,
    character: character.target,
  };
  console.log(contractAddresses);
  await new Promise((resolve) => {
    let count = 0;
    const intervalId = setInterval(() => {
      count += 1;
      console.log(count);
      if (count >= 60) {
        clearInterval(intervalId);
        resolve(1);
      }
    }, 1000);
  });
  await verify(contractAddresses);
}

async function verify({
  registry,
  inventory,
  gold,
  item,
  itemShop,
  character,
}) {
  const contracts = [
    {
      address: registry,
      contract: "contracts/ERC6551Registry.sol:ERC6551Registry",
    },
    {
      address: inventory,
      contract:
        "contracts/TextQuestCharacterInventory.sol:TextQuestCharacterInventory",
    },
    { address: gold, contract: "contracts/TextQuestGold.sol:TextQuestGold" },
    { address: item, contract: "contracts/TextQuestItem.sol:TextQuestItem" },
    {
      address: itemShop,
      contract: "contracts/TextQuestItemShop.sol:TextQuestItemShop",
      constructorArguments: [item, gold],
    },
    {
      address: character,
      contract: "contracts/TextQuestCharacter.sol:TextQuestCharacter",
      constructorArguments: [registry, inventory, gold, item],
    },
  ];

  for (const { address, contract, constructorArguments } of contracts) {
    console.log(`verify ${contract} at ${address}`);
    try {
      if (constructorArguments) {
        await hre.run("verify:verify", {
          address,
          contract,
          constructorArguments,
        });
      } else {
        await hre.run("verify:verify", { address, contract });
      }
    } catch (error) {
      console.error(
        `Verification failed for ${contract} at ${address}: ${error.message}`
      );
    }

    await new Promise((resolve) => setTimeout(resolve, 200));
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
