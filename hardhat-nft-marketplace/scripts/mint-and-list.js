const { ethers, network } = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")
const { networkConfig } = require("../helper-hardhat-config")
// const {chainId} = require("../helper-hardhat-config")
const PRICE = ethers.utils.parseEther("0.1")

async function mintAndList() {
    const nftMarketplace = await ethers.getContract("NftMarketplace")
    const randomNumber = Math.floor(Math.random() * 2)
    let basicNft
    let mintTx  ; 
    //randomly choose to mint a basic NFT or a dynamic SVG NFT (50/50 chance)
    if (randomNumber == 1) {
           // Dynamic SVG  NFT
    const highValue = ethers.utils.parseEther("4000")
    const {deployer} = await getNamedAccounts()
    basicNft = await ethers.getContract("DynamicSvgNft", deployer)
    mintTx = await basicNft.mintNft(highValue)
    console.log(`Dynamic SVG NFT index 0 tokenURI: ${await basicNft.tokenURI(0)}`)
    } else {
        basicNft = await ethers.getContract("BasicNft")
         mintTx = await basicNft.mintNft()
    }
    console.log("Minting NFT...")
    const mintTxReceipt = await mintTx.wait(1)
    const tokenId = mintTxReceipt.events[0].args.tokenId
    console.log("Approving NFT...")

    // solve this issue
    const approvalTx = await basicNft.approve(nftMarketplace.address, tokenId)
    await approvalTx.wait(1)
    console.log("Listing NFT...")
    const tx = await nftMarketplace.listItem(basicNft.address, tokenId, PRICE)
    await tx.wait(1)
    console.log("NFT Listed!")
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 at once!
        await moveBlocks(1, (sleepAmount = 1000))
    }
}

mintAndList()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })