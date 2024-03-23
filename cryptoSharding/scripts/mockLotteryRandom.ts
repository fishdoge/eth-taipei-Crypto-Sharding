import { ethers } from "hardhat";

async function main() {
  const MockLotteryRandom = await ethers.getContractFactory(
    "MockLotteryRandom"
  );

  const mockCoordinator = "0xA0Cf798816D4b9b9866b5330EEa46a18382f251e";
  const mockSubId = 1;

  const mockLotteryRandom = await MockLotteryRandom.deploy(
    mockCoordinator,
    mockSubId
  );
  await mockLotteryRandom.waitForDeployment();

  const mockLotteryRandomAddress = await mockLotteryRandom.getAddress();
  console.log(`lottery contract address is ${mockLotteryRandomAddress}`);
}

main();
