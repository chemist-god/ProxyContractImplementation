const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Proxy Contract", function () {
  let proxy, implV1, implV2;
  let admin, user, attacker;
  let proxyAsV1, proxyAsV2;

  before(async function () {
    [admin, user, attacker] = await ethers.getSigners();

    // Deploy implementations
    const V1 = await ethers.getContractFactory("ImplementationV1");
    implV1 = await V1.deploy();
    
    const V2 = await ethers.getContractFactory("ImplementationV2");
    implV2 = await V2.deploy();

    // Deploy proxy
    const Proxy = await ethers.getContractFactory("Proxy");
    proxy = await Proxy.deploy(implV1.target, admin.address);

    // Create contract instances for testing
    proxyAsV1 = await ethers.getContractAt("ImplementationV1", proxy.target);
    proxyAsV2 = await ethers.getContractAt("ImplementationV2", proxy.target);
  });

  describe("Initial State", function () {
    it("Should set correct initial implementation", async function () {
      expect(await proxy.implementation()).to.equal(implV1.target);
    });

    it("Should set correct admin", async function () {
      expect(await proxy.admin()).to.equal(admin.address);
    });
  });

  describe("Functionality", function () {
    it("Should execute through proxy (V1)", async function () {
      await proxyAsV1.setValue(42);
      expect(await proxyAsV1.value()).to.equal(42);
    });

    it("Should preserve storage after upgrade", async function () {
      // First set value in V1
      await proxyAsV1.setValue(100);
      
      // Upgrade to V2
      await proxy.connect(admin).upgradeTo(implV2.target);
      
      // Verify value persists
      expect(await proxyAsV2.value()).to.equal(100);
      
      // Test new V2 functionality
      await proxyAsV2.setValue(200);
      expect(await proxyAsV2.getValueSquared()).to.equal(40000);
    });
  });

  describe("Upgrade Mechanism", function () {
    it("Should allow admin to upgrade", async function () {
      await expect(proxy.connect(admin).upgradeTo(implV2.target))
        .to.emit(proxy, "Upgraded")
        .withArgs(implV2.target);
    });

    it("Should prevent non-admin from upgrading", async function () {
      await expect(
        proxy.connect(user).upgradeTo(implV2.target)
      ).to.be.revertedWith("Proxy: caller is not admin");
    });

    it("Should prevent upgrade to zero address", async function () {
      await expect(
        proxy.connect(admin).upgradeTo(ethers.ZeroAddress)
      ).to.be.revertedWith("Proxy: invalid implementation");
    });

    it("Should prevent upgrade to non-contract", async function () {
      await expect(
        proxy.connect(admin).upgradeTo(user.address) // EOA address
      ).to.be.revertedWith("Proxy: implementation is not contract");
    });
  });

  describe("Edge Cases", function () {
    it("Should handle ETH transfers", async function () {
      await expect(
        admin.sendTransaction({
          to: proxy.target,
          value: ethers.parseEther("1.0")
        })
      ).to.changeEtherBalance(proxy.target, ethers.parseEther("1.0"));
    });

    it("Should reject unknown function calls", async function () {
      // Encode a call to a non-existent function
      const iface = new ethers.Interface(["function nonExistentFunction()"]);
      const data = iface.encodeFunctionData("nonExistentFunction");
      
      await expect(
        user.sendTransaction({
            to: proxy.target,
            data: data
        })
      ).to.be.reverted;
    });
  });
});