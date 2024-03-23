import { ethers } from "hardhat";
const args = require("../arguments/lottery");

async function main() {
  const Lottery = await ethers.getContractFactory("Lottery");
  const lottery = await Lottery.deploy(...args);

  const lotteryAddress = await lottery.getAddress();

  console.log(`lottery contract address is ${lotteryAddress}`);
  await lottery.waitForDeployment();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
