import { network } from "hardhat";


async function main() {


  const connection =
    await network.getOrCreate();


  const ethers =
    connection.ethers;



  const [deployer] =
    await ethers.getSigners();



  console.log(
    "Deploying with:",
    deployer.address
  );



  // 1. WETH

  const WETH =
    await ethers.getContractFactory(
      "WETH9"
    );


  const weth =
    await WETH.deploy();


  await weth.waitForDeployment();


  console.log(
    "WETH:",
    await weth.getAddress()
  );





  // 2. Factory

  const Factory =
    await ethers.getContractFactory(
      "ApexV2Factory"
    );


  const factory =
    await Factory.deploy(
      deployer.address
    );


  await factory.waitForDeployment();


  console.log(
    "ApexV2Factory:",
    await factory.getAddress()
  );





  // 3. Router

  const Router =
    await ethers.getContractFactory(
      "ApexV2Router"
    );


  const router =
    await Router.deploy(
      await factory.getAddress(),
      await weth.getAddress()
    );


  await router.waitForDeployment();


  console.log(
    "Router:",
    await router.getAddress()
  );





  // 4. Apex Token

  const Token =
    await ethers.getContractFactory(
      "ApexToken"
    );


  const token =
    await Token.deploy(

      deployer.address,
      deployer.address,
      deployer.address,
      deployer.address,
      deployer.address,
      deployer.address

    );


  await token.waitForDeployment();


  console.log(
    "Token:",
    await token.getAddress()
  );





  // 5. Vesting

  const Vesting =
    await ethers.getContractFactory(
      "ApexVesting"
    );


  const vesting =
    await Vesting.deploy(
      await token.getAddress()
    );


  await vesting.waitForDeployment();


  console.log(
    "ApexVesting:",
    await vesting.getAddress()
  );





  // 6. Launch Controller

  const Launch =
    await ethers.getContractFactory(
      "ApexLaunchController"
    );


  const launch =
    await Launch.deploy(

      await token.getAddress(),

      await router.getAddress(),

      await factory.getAddress(),

      await vesting.getAddress()

    );


  await launch.waitForDeployment();


  console.log(
    "ApexLaunchController:",
    await launch.getAddress()
  );





  console.log(
    "\n✅ DEPLOY FINISHED"
  );

}



main()
.catch(
  (error)=>{
    console.error(error);
    process.exitCode = 1;
  }
);