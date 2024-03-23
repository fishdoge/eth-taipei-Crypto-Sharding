import { ethers } from "hardhat";
const args = require("../arguments/lotteryRandom");

async function main() {
  const LotteryRandom = await ethers.getContractFactory("LotteryRandom");

  const lotteryRandom = await LotteryRandom.deploy(...args);

  const lotteryRandomAddress = await lotteryRandom.getAddress();

  console.log(`lottery random contract address is ${lotteryRandomAddress}`);
  await lotteryRandom.waitForDeployment();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
