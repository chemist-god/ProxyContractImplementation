const hre = require("hardhat");

async function main() {
  const [admin] = await hre.ethers.getSigners();

  // Deploy implementations
  const V1 = await hre.ethers.getContractFactory("ImplementationV1");
  const v1 = await V1.deploy();
  await v1.waitForDeployment();

  const V2 = await hre.ethers.getContractFactory("ImplementationV2");
  const v2 = await V2.deploy();
  await v2.waitForDeployment();

  // Deploy proxy
  const Proxy = await hre.ethers.getContractFactory("Proxy");
  const proxy = await Proxy.deploy(await v1.getAddress(), admin.address);
  await proxy.waitForDeployment();

  console.log("Proxy deployed to:", await proxy.getAddress());
  console.log("Implementation V1:", await v1.getAddress());
  console.log("Implementation V2:", await v2.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});