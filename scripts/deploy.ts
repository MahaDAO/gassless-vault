import hre, { ethers } from "hardhat";

async function main() {
  const Factory = await ethers.getContractFactory("GaslessVaultFactory");
  const instance = await Factory.deploy();

  await instance.deployed();

  console.log("Contract deployed to:", instance.address);

  await hre.run("verify:verify", {
    address: instance.address,
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
