const { ethers } = require("hardhat")
const { CRYPTODEVS_NFT_CONTRACT_ADDRESS } = require("../constants")

async function main() {
    const FakeNftMarketplace = await ethers.getContractFactory("FakeNFTMarketplace");

    const fakeNFTMarketplace = await FakeNftMarketplace.deploy();

    await fakeNFTMarketplace.deployed();

    console.log("FakeNFTMarkeyplace deployed to", fakeNFTMarketplace.address);

    const CryptoDevsDao = await ethers.getContractFactory("CryptoDevsDAO");

    const cryptoDevsDao = await CryptoDevsDao.deploy(fakeNFTMarketplace.address, CRYPTODEVS_NFT_CONTRACT_ADDRESS, {
        value: ethers.utils.parseEther("0.1"),
    });

    await cryptoDevsDao.deployed();

    console.log("cryptoDevsDao deployed to", cryptoDevsDao.address);


}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error)
    process.exit(1)
})