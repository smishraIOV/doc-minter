import {HardhatUserConfig, task} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import fs from "fs";

const mnemonic = fs.readFileSync(".secret").toString().trim();

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
    },
    rskTestnet: {
      chainId: 31,
      url: 'https://public-node.testnet.rsk.co/',
      gasMultiplier: 1.1,
      accounts: {
        mnemonic: mnemonic,
        // initialIndex: 0,
        // path: "m/44'/60'/0'/0",
        // count: 10,
      },
    }
  },
  solidity: "0.8.9",
};

task("mint", "Mints DoC tokens")
    .addParam("minterAddr", "DocMinter contract address") //e.g.0xD16B3FeCBF27Ef2B79481118a48eB97995d3f294 (CHECKSUM!)
    .addParam("rbtcToMint", "The amount in wei to use for minting DoC token") // e.g. "1000000000000000", 10^15, 0.001BTC
    .addParam("totalValueToSend", "To cover minting + comissions") // e.g. "2000000000000000", 10^15, 0.001BTC
    .setAction(async (taskArgs, hre) => {
        const docMinterAddr = taskArgs.minterAddr;
        const rbtcToMint = taskArgs.rbtcToMint;
        const totalValueToSend = taskArgs.totalValueToSend;

        const accounts = await hre.ethers.getSigners();

        const DocMinter = await hre.ethers.getContractFactory("DocMinter");

        const docMinter =  await DocMinter.attach(docMinterAddr);
        console.log("DocMinter deployed to:", docMinter.address);

        const receiverAddr = await accounts[1].getAddress();
        console.log("receiverAddr:", receiverAddr);

        const refundAddr = await accounts[2].getAddress();
        console.log("refundAddr:", refundAddr);

        const result = await docMinter.mintDoc(receiverAddr, refundAddr, rbtcToMint, {value: totalValueToSend, gasLimit: 1_000_000});
        console.log("Mint result:", result);
    });

export default config;

