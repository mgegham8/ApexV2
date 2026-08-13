import { network } from "hardhat";


async function main() {

    const connection = await network.getOrCreate();
    const ethers = connection.ethers;


    // քո deploy-ից ստացած address-ները
    const WETH_ADDRESS =
        "0x5FbDB2315678afecb367f032d93F642f64180aa3";

    const FACTORY_ADDRESS =
        "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

    const ROUTER_ADDRESS =
        "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

    const TOKEN_ADDRESS =
        "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

    const VESTING_ADDRESS =
        "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9";

    const LAUNCH_ADDRESS =
        "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707";


    console.log("\n===== APEX DEPLOYMENT CHECK =====\n");


    const factory =
        await ethers.getContractAt(
            "ApexV2Factory",
            FACTORY_ADDRESS
        );


    const router =
        await ethers.getContractAt(
            "ApexV2Router",
            ROUTER_ADDRESS
        );


    const token =
        await ethers.getContractAt(
            "ApexToken",
            TOKEN_ADDRESS
        );


    const vesting =
        await ethers.getContractAt(
            "ApexVesting",
            VESTING_ADDRESS
        );


    const launch =
        await ethers.getContractAt(
            "ApexLaunchController",
            LAUNCH_ADDRESS
        );



    console.log("FACTORY");
    console.log("----------------");

    console.log(
        "feeToSetter:",
        await factory.feeToSetter()
    );


    console.log(
        "feeTo:",
        await factory.feeTo()
    );



    console.log("\nROUTER");
    console.log("----------------");

    console.log(
        "factory:",
        await router.factory()
    );


    console.log(
        "WETH:",
        await router.WETH()
    );



    console.log("\nTOKEN");
    console.log("----------------");

    console.log(
        "name:",
        await token.name()
    );

    console.log(
        "symbol:",
        await token.symbol()
    );


    console.log(
        "totalSupply:",
        (await token.totalSupply()).toString()
    );



    console.log("\nVESTING");
    console.log("----------------");

    console.log(
        "token:",
        await vesting.token()
    );



    console.log("\nLAUNCH CONTROLLER");
    console.log("----------------");

    console.log(
        "owner:",
        await launch.owner()
    );



    console.log("\nADDRESS MATCH CHECK");
    console.log("----------------");


    console.log(
        "Router Factory OK:",
        (await router.factory()) === FACTORY_ADDRESS
    );


    console.log(
        "Router WETH OK:",
        (await router.WETH()) === WETH_ADDRESS
    );


    console.log(
        "Vesting Token OK:",
        (await vesting.token()) === TOKEN_ADDRESS
    );


    console.log(
        "\n✅ CHECK FINISHED\n"
    );
}



main()
.then(() => process.exit(0))
.catch((error)=>{

    console.error(error);

    process.exit(1);

});