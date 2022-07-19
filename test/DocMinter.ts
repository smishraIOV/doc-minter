import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";
import {ethers} from "hardhat";

describe("DocMinter", function () {

  async function deployOneYearLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, receiverAccount, reminderAccount] = await ethers.getSigners();

    const mocAddr = "0x2D2249Da581D4a44C96c7f8A2CAa977B3fd6B90E";
    const docAddr = "0x2D2249Da581D4a44C96c7f8A2CAa977B3fd6B90E";
    const mocExchangeAddr = "0x2D2249Da581D4a44C96c7f8A2CAa977B3fd6B90E";
    const mocInrateAddr = "0x2D2249Da581D4a44C96c7f8A2CAa977B3fd6B90E";
    const mocVendorsAddr = "0x2D2249Da581D4a44C96c7f8A2CAa977B3fd6B90E";

    const DocMinter = await ethers.getContractFactory("DocMinter");
    const docMinter = await DocMinter.deploy(mocAddr, docAddr, mocExchangeAddr, mocInrateAddr, mocVendorsAddr);

    return { docMinter, owner, receiverAccount, reminderAccount };
  }

  describe("Receive", function () {
    it("Should receive funds", async function () {
      const { docMinter, owner } = await loadFixture(deployOneYearLockFixture);

      expect(await docMinter.provider.getBalance(docMinter.address)).to.equal(0);

      await expect(owner.sendTransaction({
        from: owner.address,
        to: docMinter.address,
        value: 1,
      })).not.to.be.reverted;

      expect(await docMinter.provider.getBalance(docMinter.address)).to.equal(1);
    });
  });
});
