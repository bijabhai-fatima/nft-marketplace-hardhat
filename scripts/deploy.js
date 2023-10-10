
const hre = require("hardhat");

async function main() { 

  // const nftMarket = await hre.ethers.deployContract("NFTMarketplace");
  const NFTMarket = await hre.ethers.getContractFactory("NFTMarket")
  const nftMarket = await NFTMarket.deploy()
  await nftMarket.deployed();

  console.log(
    `deployed to ${nftMarket.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
