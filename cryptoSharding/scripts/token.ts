import { ethers } from "hardhat";
const badgeArgs = require("../arguments/badge.ts");
const shardArgs = require("../arguments/shard.ts");

async function main() {
  const Badge = await ethers.getContractFactory("Badge");
  const badge = await Badge.deploy(...badgeArgs);

  const Shard = await ethers.getContractFactory("Shard");
  const shard = await Shard.deploy(...shardArgs);

  const shardAddress = await shard.getAddress();
  const badgeAddress = await badge.getAddress();

  console.log(`Shard contract address is ${shardAddress}`);
  console.log(`Badge contract address is ${badgeAddress}`);

  await badge.waitForDeployment();
  await shard.waitForDeployment();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
