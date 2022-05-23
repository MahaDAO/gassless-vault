import { ethers } from "hardhat";

// npx hardhat run scripts/build.ts --network bsc
async function main() {
  const [me] = await ethers.getSigners();

  const factory = await ethers.getContractAt(
    "GaslessVaultFactory",
    "0x32fc36C43Ca917349c563F65aeB76cE8B45d9002"
  );

  const BUILD_HASH = await factory.BUILD_HASH();
  const nonce = 1;

  console.log("BUILD_HASH is", BUILD_HASH);
  console.log("me", me.address);

  const packed = ethers.utils.solidityPack(
    ["bytes32", "uint256", "address"],
    [BUILD_HASH, nonce, ethers.utils.zeroPad(me.address, 32)]
  );

  const hash = ethers.utils.solidityKeccak256(["bytes"], [packed]);
  const signature = await me.signMessage(ethers.utils.arrayify(hash));

  const tx = await factory.build(nonce, me.address, signature);
  console.log(tx);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
