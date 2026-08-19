// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

interface IVerifyFactory {
    function feeTo()
        external
        view
        returns (address);

    function feeToSetter()
        external
        view
        returns (address);

    function allPairsLength()
        external
        view
        returns (uint256);

    function getPair(
        address tokenA,
        address tokenB
    )
        external
        view
        returns (address);
}

interface IVerifyRouter {
    function factory()
        external
        view
        returns (address);

    function WETH()
        external
        view
        returns (address);
}

interface IVerifyERC20 {
    function name()
        external
        view
        returns (string memory);

    function symbol()
        external
        view
        returns (string memory);

    function decimals()
        external
        view
        returns (uint8);

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address account
    )
        external
        view
        returns (uint256);
}

interface IVerifyApexToken is IVerifyERC20 {
    function MAX_SUPPLY()
        external
        view
        returns (uint256);

    function LIQUIDITY_ALLOCATION()
        external
        view
        returns (uint256);

    function COMMUNITY_ALLOCATION()
        external
        view
        returns (uint256);

    function TREASURY_ALLOCATION()
        external
        view
        returns (uint256);

    function TEAM_ALLOCATION()
        external
        view
        returns (uint256);

    function MARKETING_ALLOCATION()
        external
        view
        returns (uint256);

    function RESERVE_ALLOCATION()
        external
        view
        returns (uint256);

    function owner()
        external
        view
        returns (address);

    function pendingOwner()
        external
        view
        returns (address);

    function paused()
        external
        view
        returns (bool);
}

interface IVerifyVesting {
    function token()
        external
        view
        returns (address);

    function owner()
        external
        view
        returns (address);

    function operators(
        address account
    )
        external
        view
        returns (bool);
}

interface IVerifyLaunchController {
    function owner()
        external
        view
        returns (address);

    function pendingOwner()
        external
        view
        returns (address);

    function token()
        external
        view
        returns (address);

    function router()
        external
        view
        returns (address);

    function factory()
        external
        view
        returns (address);

    function vesting()
        external
        view
        returns (address);

    function lpToken()
        external
        view
        returns (address);

    function launched()
        external
        view
        returns (bool);
}

contract VerifyDeployment is Script {
    function run()
        external
        view
    {
        // =========================================================
        // ENV
        // =========================================================

        address weth =
            vm.envAddress(
                "WETH_ADDRESS"
            );

        address factoryAddress =
            vm.envAddress(
                "FACTORY_ADDRESS"
            );

        address routerAddress =
            vm.envAddress(
                "ROUTER_ADDRESS"
            );

        address apexTokenAddress =
            vm.envAddress(
                "APEX_TOKEN_ADDRESS"
            );

        address votingTokenAddress =
            vm.envAddress(
                "VOTING_TOKEN_ADDRESS"
            );

        address vestingAddress =
            vm.envAddress(
                "VESTING_ADDRESS"
            );

        address launchAddress =
            vm.envAddress(
                "LAUNCH_ADDRESS"
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
        // BASIC ADDRESS CHECKS
        // =========================================================

        require(
            weth != address(0),
            "ZERO_WETH"
        );

        require(
            factoryAddress != address(0),
            "ZERO_FACTORY"
        );

        require(
            routerAddress != address(0),
            "ZERO_ROUTER"
        );

        require(
            apexTokenAddress != address(0),
            "ZERO_APEX_TOKEN"
        );

        require(
            votingTokenAddress != address(0),
            "ZERO_VOTING_TOKEN"
        );

        require(
            vestingAddress != address(0),
            "ZERO_VESTING"
        );

        require(
            launchAddress != address(0),
            "ZERO_LAUNCH"
        );

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
        // CODE CHECKS
        // =========================================================

        require(
            weth.code.length > 0,
            "WETH_NO_CODE"
        );

        require(
            factoryAddress.code.length > 0,
            "FACTORY_NO_CODE"
        );

        require(
            routerAddress.code.length > 0,
            "ROUTER_NO_CODE"
        );

        require(
            apexTokenAddress.code.length > 0,
            "APEX_TOKEN_NO_CODE"
        );

        require(
            votingTokenAddress.code.length > 0,
            "VOTING_TOKEN_NO_CODE"
        );

        require(
            vestingAddress.code.length > 0,
            "VESTING_NO_CODE"
        );

        require(
            launchAddress.code.length > 0,
            "LAUNCH_NO_CODE"
        );

        // =========================================================
        // INSTANCES
        // =========================================================

        IVerifyFactory factory =
            IVerifyFactory(
                factoryAddress
            );

        IVerifyRouter router =
            IVerifyRouter(
                routerAddress
            );

        IVerifyApexToken apexToken =
            IVerifyApexToken(
                apexTokenAddress
            );

        IVerifyERC20 votingToken =
            IVerifyERC20(
                votingTokenAddress
            );

        IVerifyVesting vesting =
            IVerifyVesting(
                vestingAddress
            );

        IVerifyLaunchController launch =
            IVerifyLaunchController(
                launchAddress
            );

        // =========================================================
        // FACTORY
        // =========================================================

        address feeTo =
            factory.feeTo();

        address feeToSetter =
            factory.feeToSetter();

        uint256 pairCount =
            factory.allPairsLength();

        // =========================================================
        // ROUTER
        // =========================================================

        address routerFactory =
            router.factory();

        address routerWETH =
            router.WETH();

        // =========================================================
        // APEX TOKEN
        // =========================================================

        string memory apexName =
            apexToken.name();

        string memory apexSymbol =
            apexToken.symbol();

        uint8 apexDecimals =
            apexToken.decimals();

        uint256 apexSupply =
            apexToken.totalSupply();

        uint256 apexMaxSupply =
            apexToken.MAX_SUPPLY();

        address apexOwner =
            apexToken.owner();

        address apexPendingOwner =
            apexToken.pendingOwner();

        bool apexPaused =
            apexToken.paused();

        // =========================================================
        // VOTING TOKEN
        // =========================================================

        string memory votingName =
            votingToken.name();

        string memory votingSymbol =
            votingToken.symbol();

        uint8 votingDecimals =
            votingToken.decimals();

        uint256 votingSupply =
            votingToken.totalSupply();

        // =========================================================
        // VESTING
        // =========================================================

        address vestingToken =
            vesting.token();

        address vestingOwner =
            vesting.owner();

        bool launchIsOperator =
            vesting.operators(
                launchAddress
            );

        // =========================================================
        // LAUNCH CONTROLLER
        // =========================================================

        address launchOwner =
            launch.owner();

        address launchPendingOwner =
            launch.pendingOwner();

        address launchToken =
            launch.token();

        address launchRouter =
            launch.router();

        address launchFactory =
            launch.factory();

        address launchVesting =
            launch.vesting();

        address lpToken =
            launch.lpToken();

        bool launched =
            launch.launched();

        // =========================================================
        // CORE WIRING ASSERTIONS
        // =========================================================

        require(
            routerFactory ==
                factoryAddress,
            "ROUTER_FACTORY_MISMATCH"
        );

        require(
            routerWETH ==
                weth,
            "ROUTER_WETH_MISMATCH"
        );

        require(
            vestingToken ==
                apexTokenAddress,
            "VESTING_APEX_TOKEN_MISMATCH"
        );

        require(
            launchToken ==
                apexTokenAddress,
            "LAUNCH_APEX_TOKEN_MISMATCH"
        );

        require(
            launchRouter ==
                routerAddress,
            "LAUNCH_ROUTER_MISMATCH"
        );

        require(
            launchFactory ==
                factoryAddress,
            "LAUNCH_FACTORY_MISMATCH"
        );

        require(
            launchVesting ==
                vestingAddress,
            "LAUNCH_VESTING_MISMATCH"
        );

        require(
            launchIsOperator,
            "LAUNCH_NOT_VESTING_OPERATOR"
        );

        // =========================================================
        // APEX TOKEN METADATA ASSERTIONS
        // =========================================================

        require(
            keccak256(
                bytes(apexName)
            ) ==
                keccak256(
                    bytes("Apex Token")
                ),
            "APEX_NAME_MISMATCH"
        );

        require(
            keccak256(
                bytes(apexSymbol)
            ) ==
                keccak256(
                    bytes("APEX")
                ),
            "APEX_SYMBOL_MISMATCH"
        );

        require(
            apexDecimals == 18,
            "APEX_DECIMALS_MISMATCH"
        );

        require(
            apexSupply ==
                apexMaxSupply,
            "APEX_SUPPLY_MISMATCH"
        );

        require(
            apexSupply ==
                1_000_000_000 ether,
            "APEX_EXPECTED_SUPPLY_MISMATCH"
        );

        require(
            !apexPaused,
            "APEX_TOKEN_PAUSED"
        );

        // =========================================================
        // APEX ALLOCATION ASSERTIONS
        // =========================================================

        require(
            apexToken.balanceOf(
                liquidityWallet
            ) >=
                apexToken
                    .LIQUIDITY_ALLOCATION(),
            "LIQUIDITY_ALLOCATION_MISMATCH"
        );

        require(
            apexToken.balanceOf(
                communityWallet
            ) >=
                apexToken
                    .COMMUNITY_ALLOCATION(),
            "COMMUNITY_ALLOCATION_MISMATCH"
        );

        require(
            apexToken.balanceOf(
                treasuryWallet
            ) >=
                apexToken
                    .TREASURY_ALLOCATION(),
            "TREASURY_ALLOCATION_MISMATCH"
        );

        require(
            apexToken.balanceOf(
                teamWallet
            ) >=
                apexToken
                    .TEAM_ALLOCATION(),
            "TEAM_ALLOCATION_MISMATCH"
        );

        require(
            apexToken.balanceOf(
                marketingWallet
            ) >=
                apexToken
                    .MARKETING_ALLOCATION(),
            "MARKETING_ALLOCATION_MISMATCH"
        );

        require(
            apexToken.balanceOf(
                reserveWallet
            ) >=
                apexToken
                    .RESERVE_ALLOCATION(),
            "RESERVE_ALLOCATION_MISMATCH"
        );

        // =========================================================
        // VOTING TOKEN ASSERTIONS
        // =========================================================

        require(
            keccak256(
                bytes(votingName)
            ) ==
                keccak256(
                    bytes(
                        "Apex Voting Token"
                    )
                ),
            "VOTING_NAME_MISMATCH"
        );

        require(
            keccak256(
                bytes(votingSymbol)
            ) ==
                keccak256(
                    bytes("AVT")
                ),
            "VOTING_SYMBOL_MISMATCH"
        );

        require(
            votingDecimals == 18,
            "VOTING_DECIMALS_MISMATCH"
        );

        require(
            votingSupply ==
                1_000_000 ether,
            "VOTING_SUPPLY_MISMATCH"
        );

        require(
            apexTokenAddress !=
                votingTokenAddress,
            "APEX_AND_VOTING_TOKEN_SAME"
        );

        // =========================================================
        // FACTORY ASSERTIONS
        // =========================================================

        require(
            feeToSetter !=
                address(0),
            "ZERO_FEE_TO_SETTER"
        );

        // =========================================================
        // PAIR / LAUNCH ASSERTIONS
        // =========================================================

        address factoryPair =
            factory.getPair(
                apexTokenAddress,
                weth
            );

        if (launched) {
            require(
                lpToken != address(0),
                "ZERO_LP_AFTER_LAUNCH"
            );

            require(
                lpToken.code.length > 0,
                "LP_NO_CODE"
            );

            require(
                factoryPair ==
                    lpToken,
                "LP_PAIR_MISMATCH"
            );
        } else {
            require(
                lpToken ==
                    address(0),
                "LP_SET_BEFORE_LAUNCH"
            );

            require(
                factoryPair ==
                    address(0),
                "PAIR_EXISTS_BEFORE_LAUNCH"
            );
        }

        // =========================================================
        // OUTPUT
        // =========================================================

        console2.log("");

        console2.log(
            "========================================"
        );

        console2.log(
            "APEX V2 DEPLOYMENT VERIFICATION"
        );

        console2.log(
            "========================================"
        );

        // =========================================================
        // FACTORY OUTPUT
        // =========================================================

        console2.log("");

        console2.log(
            "FACTORY"
        );

        console2.log(
            "Address:",
            factoryAddress
        );

        console2.log(
            "feeToSetter:",
            feeToSetter
        );

        console2.log(
            "feeTo:",
            feeTo
        );

        console2.log(
            "Pairs:",
            pairCount
        );

        // =========================================================
        // ROUTER OUTPUT
        // =========================================================

        console2.log("");

        console2.log(
            "ROUTER"
        );

        console2.log(
            "Address:",
            routerAddress
        );

        console2.log(
            "Factory:",
            routerFactory
        );

        console2.log(
            "WETH:",
            routerWETH
        );

        // =========================================================
        // APEX TOKEN OUTPUT
        // =========================================================

        console2.log("");

        console2.log(
            "APEX TOKEN"
        );

        console2.log(
            "Address:",
            apexTokenAddress
        );

        console2.log(
            "Name:",
            apexName
        );

        console2.log(
            "Symbol:",
            apexSymbol
        );

        console2.log(
            "Decimals:",
            uint256(
                apexDecimals
            )
        );

        console2.log(
            "Total supply:",
            apexSupply
        );

        console2.log(
            "Max supply:",
            apexMaxSupply
        );

        console2.log(
            "Owner:",
            apexOwner
        );

        console2.log(
            "Pending owner:",
            apexPendingOwner
        );

        console2.log(
            "Paused:",
            apexPaused
        );

        // =========================================================
        // APEX ALLOCATIONS OUTPUT
        // =========================================================

        console2.log("");

        console2.log(
            "APEX ALLOCATIONS"
        );

        console2.log(
            "Liquidity wallet:",
            liquidityWallet
        );

        console2.log(
            "Liquidity balance:",
            apexToken.balanceOf(
                liquidityWallet
            )
        );

        console2.log(
            "Community wallet:",
            communityWallet
        );

        console2.log(
            "Community balance:",
            apexToken.balanceOf(
                communityWallet
            )
        );

        console2.log(
            "Treasury wallet:",
            treasuryWallet
        );

        console2.log(
            "Treasury balance:",
            apexToken.balanceOf(
                treasuryWallet
            )
        );

        console2.log(
            "Team wallet:",
            teamWallet
        );

        console2.log(
            "Team balance:",
            apexToken.balanceOf(
                teamWallet
            )
        );

        console2.log(
            "Marketing wallet:",
            marketingWallet
        );

        console2.log(
            "Marketing balance:",
            apexToken.balanceOf(
                marketingWallet
            )
        );

        console2.log(
            "Reserve wallet:",
            reserveWallet
        );

        console2.log(
            "Reserve balance:",
            apexToken.balanceOf(
                reserveWallet
            )
        );

        // =========================================================
        // VOTING TOKEN OUTPUT
        // =========================================================

        console2.log("");

        console2.log(
            "VOTING TOKEN"
        );

        console2.log(
            "Address:",
            votingTokenAddress
        );

        console2.log(
            "Name:",
            votingName
        );

        console2.log(
            "Symbol:",
            votingSymbol
        );

        console2.log(
            "Decimals:",
            uint256(
                votingDecimals
            )
        );

        console2.log(
            "Total supply:",
            votingSupply
        );

        // =========================================================
        // VESTING OUTPUT
        // =========================================================

        console2.log("");

        console2.log(
            "VESTING"
        );

        console2.log(
            "Address:",
            vestingAddress
        );

        console2.log(
            "Token:",
            vestingToken
        );

        console2.log(
            "Owner:",
            vestingOwner
        );

        console2.log(
            "Launch operator:",
            launchIsOperator
        );

        // =========================================================
        // LAUNCH OUTPUT
        // =========================================================

        console2.log("");

        console2.log(
            "LAUNCH CONTROLLER"
        );

        console2.log(
            "Address:",
            launchAddress
        );

        console2.log(
            "Owner:",
            launchOwner
        );

        console2.log(
            "Pending owner:",
            launchPendingOwner
        );

        console2.log(
            "APEX token:",
            launchToken
        );

        console2.log(
            "Router:",
            launchRouter
        );

        console2.log(
            "Factory:",
            launchFactory
        );

        console2.log(
            "Vesting:",
            launchVesting
        );

        console2.log(
            "LP token:",
            lpToken
        );

        console2.log(
            "Factory pair:",
            factoryPair
        );

        console2.log(
            "Launched:",
            launched
        );

        // =========================================================
        // FINAL
        // =========================================================

        console2.log("");

        console2.log(
            "========================================"
        );

        console2.log(
            "DEPLOYMENT VERIFICATION PASSED"
        );

        console2.log(
            "========================================"
        );
    }
}