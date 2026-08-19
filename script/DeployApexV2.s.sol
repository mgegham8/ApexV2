// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {
    ApexV2Factory
} from "../src/contracts/ApexV2Factory.sol";

import {
    ApexV2Router
} from "../src/contracts/ApexV2Router.sol";

import {
    ApexToken
} from "../src/contracts/token/ApexToken.sol";

import {
    VotingToken
} from "../src/contracts/governance/VotingToken.sol";

import {
    ApexVesting
} from "../src/contracts/launch/ApexVesting.sol";

import {
    ApexLaunchController
} from "../src/contracts/launch/ApexLaunchController.sol";

import {
    WETH9
} from "../src/contracts/test/WETH9.sol";


contract DeployApexV2 is Script {

    function run()
        external
        returns (
            address weth,
            address factory,
            address router,
            address apexToken,
            address votingToken,
            address vesting,
            address launchController
        )
    {
        // =========================================================
        // ENV
        // =========================================================

        uint256 deployerPrivateKey =
            vm.envUint(
                "PRIVATE_KEY"
            );

        address deployer =
            vm.addr(
                deployerPrivateKey
            );


        address liquidityWallet =
            vm.envAddress(
                "LIQUIDITY_WALLET"
            );

        address communityWallet =
            vm.envAddress(
                "COMMUNITY_WALLET"
            );

        address treasuryWallet =
            vm.envAddress(
                "TREASURY_WALLET"
            );

        address teamWallet =
            vm.envAddress(
                "TEAM_WALLET"
            );

        address marketingWallet =
            vm.envAddress(
                "MARKETING_WALLET"
            );

        address reserveWallet =
            vm.envAddress(
                "RESERVE_WALLET"
            );


        // =========================================================
        // ENV VALIDATION
        // =========================================================

        require(
            liquidityWallet != address(0),
            "ZERO_LIQUIDITY_WALLET"
        );

        require(
            communityWallet != address(0),
            "ZERO_COMMUNITY_WALLET"
        );

        require(
            treasuryWallet != address(0),
            "ZERO_TREASURY_WALLET"
        );

        require(
            teamWallet != address(0),
            "ZERO_TEAM_WALLET"
        );

        require(
            marketingWallet != address(0),
            "ZERO_MARKETING_WALLET"
        );

        require(
            reserveWallet != address(0),
            "ZERO_RESERVE_WALLET"
        );


        // =========================================================
        // DEPLOYMENT INFO
        // =========================================================

        console2.log(
            "========================================"
        );

        console2.log(
            "APEX V2 DEPLOYMENT"
        );

        console2.log(
            "========================================"
        );

        console2.log(
            "Deployer:",
            deployer
        );

        console2.log(
            "Chain ID:",
            block.chainid
        );

        console2.log(
            "Deployer balance:",
            deployer.balance
        );


        console2.log("");

        console2.log(
            "TOKEN ALLOCATION WALLETS"
        );

        console2.log(
            "Liquidity:",
            liquidityWallet
        );

        console2.log(
            "Community:",
            communityWallet
        );

        console2.log(
            "Treasury:",
            treasuryWallet
        );

        console2.log(
            "Team:",
            teamWallet
        );

        console2.log(
            "Marketing:",
            marketingWallet
        );

        console2.log(
            "Reserve:",
            reserveWallet
        );


        // =========================================================
        // START BROADCAST
        // =========================================================

        vm.startBroadcast(
            deployerPrivateKey
        );


        // =========================================================
        // WETH
        // =========================================================

        WETH9 wethContract =
            new WETH9();

        weth =
            address(
                wethContract
            );


        // =========================================================
        // FACTORY
        // =========================================================

        ApexV2Factory factoryContract =
            new ApexV2Factory(
                deployer
            );

        factory =
            address(
                factoryContract
            );


        // =========================================================
        // ROUTER
        // =========================================================

        ApexV2Router routerContract =
            new ApexV2Router(
                factory,
                weth
            );

        router =
            address(
                routerContract
            );


        // =========================================================
        // APEX PRODUCTION TOKEN
        // =========================================================

        ApexToken apexTokenContract =
            new ApexToken(
                liquidityWallet,
                communityWallet,
                treasuryWallet,
                teamWallet,
                marketingWallet,
                reserveWallet
            );

        apexToken =
            address(
                apexTokenContract
            );


        // =========================================================
        // GOVERNANCE VOTING TOKEN
        // =========================================================

        VotingToken votingTokenContract =
            new VotingToken();

        votingToken =
            address(
                votingTokenContract
            );


        // =========================================================
        // VESTING
        // =========================================================

        ApexVesting vestingContract =
            new ApexVesting(
                apexToken
            );

        vesting =
            address(
                vestingContract
            );


        // =========================================================
        // LAUNCH CONTROLLER
        // =========================================================

        ApexLaunchController launchContract =
            new ApexLaunchController(
                apexToken,
                router,
                factory,
                vesting
            );

        launchController =
            address(
                launchContract
            );


        // =========================================================
        // AUTHORIZE LAUNCH CONTROLLER AS VESTING OPERATOR
        // =========================================================

        vestingContract.setOperator(
            launchController,
            true
        );


        // =========================================================
        // STOP BROADCAST
        // =========================================================

        vm.stopBroadcast();


        // =========================================================
        // POST-DEPLOY ASSERTIONS
        // =========================================================

        require(
            routerContract.factory() ==
                factory,
            "ROUTER_FACTORY_MISMATCH"
        );

        require(
            routerContract.WETH() ==
                weth,
            "ROUTER_WETH_MISMATCH"
        );


        // =========================================================
        // APEX TOKEN ASSERTIONS
        // =========================================================

        require(
            apexTokenContract.totalSupply() ==
                apexTokenContract.MAX_SUPPLY(),
            "APEX_SUPPLY_MISMATCH"
        );

        require(
            apexTokenContract.balanceOf(
                liquidityWallet
            ) ==
                apexTokenContract
                    .LIQUIDITY_ALLOCATION(),
            "LIQUIDITY_ALLOCATION_MISMATCH"
        );

        require(
            apexTokenContract.balanceOf(
                communityWallet
            ) ==
                apexTokenContract
                    .COMMUNITY_ALLOCATION(),
            "COMMUNITY_ALLOCATION_MISMATCH"
        );

        require(
            apexTokenContract.balanceOf(
                treasuryWallet
            ) ==
                apexTokenContract
                    .TREASURY_ALLOCATION(),
            "TREASURY_ALLOCATION_MISMATCH"
        );

        require(
            apexTokenContract.balanceOf(
                teamWallet
            ) ==
                apexTokenContract
                    .TEAM_ALLOCATION(),
            "TEAM_ALLOCATION_MISMATCH"
        );

        require(
            apexTokenContract.balanceOf(
                marketingWallet
            ) ==
                apexTokenContract
                    .MARKETING_ALLOCATION(),
            "MARKETING_ALLOCATION_MISMATCH"
        );

        require(
            apexTokenContract.balanceOf(
                reserveWallet
            ) ==
                apexTokenContract
                    .RESERVE_ALLOCATION(),
            "RESERVE_ALLOCATION_MISMATCH"
        );


        // =========================================================
        // VESTING ASSERTIONS
        // =========================================================

        require(
            address(
                vestingContract.token()
            ) ==
                apexToken,
            "VESTING_TOKEN_MISMATCH"
        );

        require(
            vestingContract.operators(
                launchController
            ),
            "LAUNCH_NOT_VESTING_OPERATOR"
        );


        // =========================================================
        // LAUNCH CONTROLLER ASSERTIONS
        // =========================================================

        require(
            launchContract.token() ==
                apexToken,
            "LAUNCH_TOKEN_MISMATCH"
        );

        require(
            launchContract.router() ==
                router,
            "LAUNCH_ROUTER_MISMATCH"
        );

        require(
            launchContract.factory() ==
                factory,
            "LAUNCH_FACTORY_MISMATCH"
        );

        require(
            launchContract.vesting() ==
                vesting,
            "LAUNCH_VESTING_MISMATCH"
        );

        require(
            !launchContract.launched(),
            "LAUNCH_ALREADY_ACTIVE"
        );


        // =========================================================
        // FACTORY ASSERTIONS
        // =========================================================

        require(
            factoryContract.feeToSetter() ==
                deployer,
            "FACTORY_FEE_SETTER_MISMATCH"
        );


        // =========================================================
        // OUTPUT
        // =========================================================

        console2.log("");

        console2.log(
            "========================================"
        );

        console2.log(
            "DEPLOYMENT SUCCESS"
        );

        console2.log(
            "========================================"
        );


        console2.log(
            "WETH:",
            weth
        );

        console2.log(
            "Factory:",
            factory
        );

        console2.log(
            "Router:",
            router
        );


        console2.log("");

        console2.log(
            "ApexToken (APEX):",
            apexToken
        );

        console2.log(
            "ApexToken total supply:",
            apexTokenContract.totalSupply()
        );


        console2.log("");

        console2.log(
            "VotingToken (AVT):",
            votingToken
        );

        console2.log(
            "VotingToken total supply:",
            votingTokenContract.totalSupply()
        );


        console2.log("");

        console2.log(
            "Vesting:",
            vesting
        );

        console2.log(
            "LaunchController:",
            launchController
        );


        console2.log("");

        console2.log(
            "LaunchController is Vesting operator:",
            vestingContract.operators(
                launchController
            )
        );


        console2.log(
            "Launch status:",
            launchContract.launched()
        );


        console2.log(
            "========================================"
        );
    }
}