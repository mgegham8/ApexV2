// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/contracts/launch/ApexVesting.sol";
import "../src/contracts/test/MockERC20.sol";

contract DeployApexVesting is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Տեղադրում ենք թոկենը
        MockERC20 token = new MockERC20("Apex Token", "APEX");
        console.log("MockERC20 deployed at:", address(token));

        // 2. Տեղադրում ենք ApexVesting պայմանագիրը
        ApexVesting vesting = new ApexVesting(address(token));
        console.log("ApexVesting deployed at:", address(vesting));

        // 3. Սահմանում ենք օպերատոր
        address operator = deployer;
        vesting.setOperator(operator, true);
        console.log("Operator set:", operator);

        // 4. Թոկեններ ենք փոխանցում vesting պայմանագրին
        uint256 totalAllocation = 1000000e18; // 1 միլիոն թոկեն
        token.mint(address(vesting), totalAllocation);
        console.log("Tokens minted and transferred to vesting contract:", totalAllocation);

        // 5. Փորձնական vesting ստեղծում
        address beneficiary = address(0x1234567890123456789012345678901234567890);
        uint256 amount = 10000e18;
        uint256 startTime = block.timestamp;
        uint256 cliff = 30 days;
        uint256 duration = 365 days;

        vesting.createVesting(beneficiary, amount, startTime, cliff, duration);
        console.log("Sample vesting created for beneficiary:", beneficiary);

        vm.stopBroadcast();
    }
}