import hre, { ethers } from "hardhat";

async function main() {
  const Factory = await ethers.getContractFactory("GaslessVaultFactory");
  const instance = await Factory.deploy();

  await instance.deployed();

  console.log("Contract deployed to:", instance.address);

  await hre.run("verify:verify", {
    address: instance.address,
    // constructorArguments: [
    //   "0xca41f33c4415734993ffd22be9d2b7baf570d3a7",
    //   "0x4b8f11f8fa64cd7c2d7b7e96be214ed9ddf7bfbc",
    // ],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
