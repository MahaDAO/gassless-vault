import hre, { ethers } from "hardhat";

async function main() {
  // const Factory = await ethers.getContractFactory("GaslessVaultFactory");
  // const instance = await Factory.deploy();

  // await instance.deployed();

  // console.log("Contract deployed to:", instance.address);

  await hre.run("verify:verify", {
    address: "0x8180dc9AF65F821cc4C2bea21B6C85F8eF2d50AE",
    constructorArguments: [
      // "0xca41f33c4415734993ffd22be9d2b7baf570d3a7",
      "0x32fc36C43Ca917349c563F65aeB76cE8B45d9002",
    ],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
