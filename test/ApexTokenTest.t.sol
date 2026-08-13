// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/contracts/token/ApexToken.sol";

contract ApexTokenTest is Test {

    ApexToken public token;

    address public liquidity;
    address public community;
    address public treasury;
    address public team;
    address public marketing;
    address public reserve;

    address public alice;
    address public bob;

    uint256 constant LIQUIDITY_ALLOCATION =
        200_000_000 ether;

    uint256 constant COMMUNITY_ALLOCATION =
        250_000_000 ether;

    uint256 constant TREASURY_ALLOCATION =
        200_000_000 ether;

    uint256 constant TEAM_ALLOCATION =
        150_000_000 ether;

    uint256 constant MARKETING_ALLOCATION =
        100_000_000 ether;

    uint256 constant RESERVE_ALLOCATION =
        100_000_000 ether;

    uint256 constant MAX_SUPPLY =
        1_000_000_000 ether;


    function setUp() public {

        liquidity = makeAddr("liquidity");
        community = makeAddr("community");
        treasury = makeAddr("treasury");
        team = makeAddr("team");
        marketing = makeAddr("marketing");
        reserve = makeAddr("reserve");

        alice = makeAddr("alice");
        bob = makeAddr("bob");

        token = new ApexToken(
            liquidity,
            community,
            treasury,
            team,
            marketing,
            reserve
        );
    }


    // =============================================================
    // CONSTRUCTOR
    // =============================================================

    function testConstructorNameAndSymbol() public {

        assertEq(
            token.name(),
            "Apex Token"
        );

        assertEq(
            token.symbol(),
            "APEX"
        );

        assertEq(
            token.decimals(),
            18
        );
    }


    function testConstructorOwnerIsDeployer() public {

        assertEq(
            token.owner(),
            address(this)
        );
    }


    function testConstructorAllocations() public {

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION
        );

        assertEq(
            token.balanceOf(community),
            COMMUNITY_ALLOCATION
        );

        assertEq(
            token.balanceOf(treasury),
            TREASURY_ALLOCATION
        );

        assertEq(
            token.balanceOf(team),
            TEAM_ALLOCATION
        );

        assertEq(
            token.balanceOf(marketing),
            MARKETING_ALLOCATION
        );

        assertEq(
            token.balanceOf(reserve),
            RESERVE_ALLOCATION
        );
    }


    function testConstructorTotalSupplyEqualsMaxSupply() public {

        assertEq(
            token.totalSupply(),
            MAX_SUPPLY
        );
    }


    function testConstantAllocationsEqualMaxSupply() public {

        uint256 total =
            token.LIQUIDITY_ALLOCATION()
            + token.COMMUNITY_ALLOCATION()
            + token.TREASURY_ALLOCATION()
            + token.TEAM_ALLOCATION()
            + token.MARKETING_ALLOCATION()
            + token.RESERVE_ALLOCATION();

        assertEq(
            total,
            token.MAX_SUPPLY()
        );
    }


    function testConstructorRejectsZeroLiquidity() public {

        vm.expectRevert("zero address");

        new ApexToken(
            address(0),
            community,
            treasury,
            team,
            marketing,
            reserve
        );
    }


    function testConstructorRejectsZeroCommunity() public {

        vm.expectRevert("zero address");

        new ApexToken(
            liquidity,
            address(0),
            treasury,
            team,
            marketing,
            reserve
        );
    }


    function testConstructorRejectsZeroTreasury() public {

        vm.expectRevert("zero address");

        new ApexToken(
            liquidity,
            community,
            address(0),
            team,
            marketing,
            reserve
        );
    }


    function testConstructorRejectsZeroTeam() public {

        vm.expectRevert("zero address");

        new ApexToken(
            liquidity,
            community,
            treasury,
            address(0),
            marketing,
            reserve
        );
    }


    function testConstructorRejectsZeroMarketing() public {

        vm.expectRevert("zero address");

        new ApexToken(
            liquidity,
            community,
            treasury,
            team,
            address(0),
            reserve
        );
    }


    function testConstructorRejectsZeroReserve() public {

        vm.expectRevert("zero address");

        new ApexToken(
            liquidity,
            community,
            treasury,
            team,
            marketing,
            address(0)
        );
    }


    // =============================================================
    // ERC20
    // =============================================================

    function testTransferWorksWhenNotPaused() public {

        uint256 amount = 100 ether;

        vm.prank(liquidity);

        bool success =
            token.transfer(
                alice,
                amount
            );

        assertTrue(success);

        assertEq(
            token.balanceOf(alice),
            amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );
    }


    function testTransferFromWorksWhenNotPaused() public {

        uint256 amount = 100 ether;

        vm.startPrank(liquidity);

        token.approve(
            alice,
            amount
        );

        vm.stopPrank();

        vm.prank(alice);

        bool success =
            token.transferFrom(
                liquidity,
                bob,
                amount
            );

        assertTrue(success);

        assertEq(
            token.balanceOf(bob),
            amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );

        assertEq(
            token.allowance(liquidity, alice),
            0
        );
    }


    function testBurnWorksWhenNotPaused() public {

        uint256 amount = 100 ether;

        uint256 beforeSupply =
            token.totalSupply();

        vm.prank(liquidity);

        token.burn(amount);

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );

        assertEq(
            token.totalSupply(),
            beforeSupply - amount
        );
    }


    function testBurnFromWorksWhenNotPaused() public {

        uint256 amount = 100 ether;

        vm.startPrank(liquidity);

        token.approve(
            alice,
            amount
        );

        vm.stopPrank();

        vm.prank(alice);

        token.burnFrom(
            liquidity,
            amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );

        assertEq(
            token.totalSupply(),
            MAX_SUPPLY - amount
        );

        assertEq(
            token.allowance(liquidity, alice),
            0
        );
    }


    // =============================================================
    // PAUSE
    // =============================================================

    function testOwnerCanPause() public {

        assertFalse(
            token.paused()
        );

        token.pause();

        assertTrue(
            token.paused()
        );
    }


    function testOwnerCanUnpause() public {

        token.pause();

        assertTrue(
            token.paused()
        );

        token.unpause();

        assertFalse(
            token.paused()
        );
    }


    function testNonOwnerCannotPause() public {

        vm.prank(alice);

        vm.expectRevert();

        token.pause();
    }


    function testNonOwnerCannotUnpause() public {

        vm.prank(alice);

        vm.expectRevert();

        token.unpause();
    }


    function testTransferRevertsWhenPaused() public {

        token.pause();

        vm.prank(liquidity);

        vm.expectRevert("Token paused");

        token.transfer(
            alice,
            100 ether
        );
    }


    function testTransferFromRevertsWhenPaused() public {

        vm.prank(liquidity);

        token.approve(
            alice,
            100 ether
        );

        token.pause();

        vm.prank(alice);

        vm.expectRevert("Token paused");

        token.transferFrom(
            liquidity,
            bob,
            100 ether
        );
    }


    function testBurnRevertsWhenPaused() public {

        token.pause();

        vm.prank(liquidity);

        vm.expectRevert("Token paused");

        token.burn(
            100 ether
        );
    }


    function testBurnFromRevertsWhenPaused() public {

        vm.prank(liquidity);

        token.approve(
            alice,
            100 ether
        );

        token.pause();

        vm.prank(alice);

        vm.expectRevert("Token paused");

        token.burnFrom(
            liquidity,
            100 ether
        );
    }


    function testTransferWorksAgainAfterUnpause() public {

        token.pause();

        token.unpause();

        vm.prank(liquidity);

        token.transfer(
            alice,
            100 ether
        );

        assertEq(
            token.balanceOf(alice),
            100 ether
        );
    }


    function testPauseCannotBeCalledTwice() public {

        token.pause();

        vm.expectRevert();

        token.pause();
    }


    function testUnpauseCannotBeCalledWhenNotPaused() public {

        vm.expectRevert();

        token.unpause();
    }


    // =============================================================
    // OWNERSHIP
    // =============================================================

    function testOwnershipTransferRequiresAcceptance() public {

        token.transferOwnership(alice);

        assertEq(
            token.owner(),
            address(this)
        );

        assertEq(
            token.pendingOwner(),
            alice
        );
    }


    function testPendingOwnerCanAcceptOwnership() public {

        token.transferOwnership(alice);

        vm.prank(alice);

        token.acceptOwnership();

        assertEq(
            token.owner(),
            alice
        );

        assertEq(
            token.pendingOwner(),
            address(0)
        );
    }


    function testOldOwnerLosesPausePermissionAfterOwnershipTransfer() public {

        token.transferOwnership(alice);

        vm.prank(alice);

        token.acceptOwnership();

        vm.expectRevert();

        token.pause();
    }


    function testNewOwnerCanPauseAfterOwnershipTransfer() public {

        token.transferOwnership(alice);

        vm.prank(alice);

        token.acceptOwnership();

        vm.prank(alice);

        token.pause();

        assertTrue(
            token.paused()
        );
    }


    // =============================================================
    // FUZZ
    // =============================================================

    function testFuzzTransferDoesNotChangeTotalSupply(
        uint256 amount
    )
        public
    {

        amount =
            bound(
                amount,
                0,
                LIQUIDITY_ALLOCATION
            );

        uint256 beforeSupply =
            token.totalSupply();

        vm.prank(liquidity);

        token.transfer(
            alice,
            amount
        );

        assertEq(
            token.totalSupply(),
            beforeSupply
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );

        assertEq(
            token.balanceOf(alice),
            amount
        );
    }


    function testFuzzBurnCannotExceedBalance(
        uint256 amount
    )
        public
    {

        amount =
            bound(
                amount,
                0,
                LIQUIDITY_ALLOCATION
            );

        uint256 beforeSupply =
            token.totalSupply();

        vm.prank(liquidity);

        token.burn(amount);

        assertEq(
            token.totalSupply(),
            beforeSupply - amount
        );

        assertEq(
            token.balanceOf(liquidity),
            LIQUIDITY_ALLOCATION - amount
        );
    }


    // =============================================================
    // ERC20 PERMIT
    // =============================================================

    function testPermitWorks() public {

        uint256 privateKey = 0xA11CE;

        address permitOwner =
            vm.addr(privateKey);

        uint256 amount =
            100 ether;

        uint256 deadline =
            block.timestamp + 1 days;


        /*
         * Give the permit owner some APEX.
         *
         * address(this) does NOT own tokens after deployment.
         * The liquidity allocation does.
         */
        vm.prank(liquidity);

        token.transfer(
            permitOwner,
            amount
        );


        uint256 nonce =
            token.nonces(permitOwner);


        bytes32 permitTypeHash =
            keccak256(
                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
            );


        bytes32 structHash =
            keccak256(
                abi.encode(
                    permitTypeHash,
                    permitOwner,
                    alice,
                    amount,
                    nonce,
                    deadline
                )
            );


        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    structHash
                )
            );


        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(
                privateKey,
                digest
            );


        token.permit(
            permitOwner,
            alice,
            amount,
            deadline,
            v,
            r,
            s
        );


        assertEq(
            token.allowance(
                permitOwner,
                alice
            ),
            amount
        );


        assertEq(
            token.nonces(permitOwner),
            nonce + 1
        );
    }


    function testPermitExpiredDeadlineReverts() public {

        uint256 privateKey = 0xA11CE;

        address permitOwner =
            vm.addr(privateKey);

        uint256 amount =
            100 ether;

        uint256 deadline =
            block.timestamp - 1;


        uint256 nonce =
            token.nonces(permitOwner);


        bytes32 permitTypeHash =
            keccak256(
                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
            );


        bytes32 structHash =
            keccak256(
                abi.encode(
                    permitTypeHash,
                    permitOwner,
                    alice,
                    amount,
                    nonce,
                    deadline
                )
            );


        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    structHash
                )
            );


        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(
                privateKey,
                digest
            );


        vm.expectRevert();

        token.permit(
            permitOwner,
            alice,
            amount,
            deadline,
            v,
            r,
            s
        );
    }
    // =============================================================
// ERC20 EDGE CASES
// =============================================================

function testTransferZeroAmount() public {

    uint256 beforeLiquidity =
        token.balanceOf(liquidity);

    uint256 beforeAlice =
        token.balanceOf(alice);

    vm.prank(liquidity);

    bool success =
        token.transfer(
            alice,
            0
        );

    assertTrue(success);

    assertEq(
        token.balanceOf(liquidity),
        beforeLiquidity
    );

    assertEq(
        token.balanceOf(alice),
        beforeAlice
    );
}


function testTransferToSelf() public {

    uint256 amount =
        100 ether;

    uint256 beforeBalance =
        token.balanceOf(liquidity);

    vm.prank(liquidity);

    bool success =
        token.transfer(
            liquidity,
            amount
        );

    assertTrue(success);

    assertEq(
        token.balanceOf(liquidity),
        beforeBalance
    );
}


function testApproveZeroAmount() public {

    vm.prank(liquidity);

    bool success =
        token.approve(
            alice,
            0
        );

    assertTrue(success);

    assertEq(
        token.allowance(
            liquidity,
            alice
        ),
        0
    );
}


function testApproveCanBeUpdated() public {

    vm.startPrank(liquidity);

    token.approve(
        alice,
        100 ether
    );

    assertEq(
        token.allowance(
            liquidity,
            alice
        ),
        100 ether
    );

    token.approve(
        alice,
        200 ether
    );

    vm.stopPrank();

    assertEq(
        token.allowance(
            liquidity,
            alice
        ),
        200 ether
    );
}


function testTransferFromZeroAmount() public {

    vm.prank(liquidity);

    token.approve(
        alice,
        100 ether
    );

    uint256 beforeSupply =
        token.totalSupply();

    vm.prank(alice);

    bool success =
        token.transferFrom(
            liquidity,
            bob,
            0
        );

    assertTrue(success);

    assertEq(
        token.totalSupply(),
        beforeSupply
    );

    assertEq(
        token.balanceOf(bob),
        0
    );

    assertEq(
        token.allowance(
            liquidity,
            alice
        ),
        100 ether
    );
}


function testBurnZeroAmount() public {

    uint256 beforeSupply =
        token.totalSupply();

    uint256 beforeBalance =
        token.balanceOf(liquidity);

    vm.prank(liquidity);

    token.burn(0);

    assertEq(
        token.totalSupply(),
        beforeSupply
    );

    assertEq(
        token.balanceOf(liquidity),
        beforeBalance
    );
}


// =============================================================
// ALLOWANCE EDGE CASES
// =============================================================

function testTransferFromConsumesAllowance() public {

    uint256 amount =
        100 ether;

    vm.prank(liquidity);

    token.approve(
        alice,
        300 ether
    );

    vm.prank(alice);

    token.transferFrom(
        liquidity,
        bob,
        amount
    );

    assertEq(
        token.allowance(
            liquidity,
            alice
        ),
        200 ether
    );
}


function testTransferFromMaxAllowanceDoesNotDecrease() public {

    uint256 amount =
        100 ether;

    vm.prank(liquidity);

    token.approve(
        alice,
        type(uint256).max
    );

    vm.prank(alice);

    token.transferFrom(
        liquidity,
        bob,
        amount
    );

    assertEq(
        token.allowance(
            liquidity,
            alice
        ),
        type(uint256).max
    );
}


function testBurnFromMaxAllowanceDoesNotDecrease() public {

    uint256 amount =
        100 ether;

    vm.prank(liquidity);

    token.approve(
        alice,
        type(uint256).max
    );

    vm.prank(alice);

    token.burnFrom(
        liquidity,
        amount
    );

    assertEq(
        token.allowance(
            liquidity,
            alice
        ),
        type(uint256).max
    );
}


// =============================================================
// PAUSE EDGE CASES
// =============================================================

function testPauseBlocksTransferFromButNotApproval() public {

    token.pause();

    vm.prank(liquidity);

    bool success =
        token.approve(
            alice,
            100 ether
        );

    assertTrue(success);

    assertEq(
        token.allowance(
            liquidity,
            alice
        ),
        100 ether
    );
}


function testPauseDoesNotChangeBalances() public {

    uint256 liquidityBalance =
        token.balanceOf(liquidity);

    uint256 aliceBalance =
        token.balanceOf(alice);

    uint256 supply =
        token.totalSupply();

    token.pause();

    assertEq(
        token.balanceOf(liquidity),
        liquidityBalance
    );

    assertEq(
        token.balanceOf(alice),
        aliceBalance
    );

    assertEq(
        token.totalSupply(),
        supply
    );
}


function testPauseThenUnpauseRestoresAllTokenOperations() public {

    token.pause();

    token.unpause();

    vm.startPrank(liquidity);

    token.approve(
        alice,
        100 ether
    );

    vm.stopPrank();

    vm.prank(alice);

    token.transferFrom(
        liquidity,
        bob,
        100 ether
    );

    assertEq(
        token.balanceOf(bob),
        100 ether
    );
}


// =============================================================
// OWNERSHIP EDGE CASES
// =============================================================

function testPendingOwnerCannotPauseBeforeAcceptance() public {

    token.transferOwnership(alice);

    vm.prank(alice);

    vm.expectRevert();

    token.pause();
}


function testOnlyCurrentOwnerCanTransferOwnership() public {

    vm.prank(alice);

    vm.expectRevert();

    token.transferOwnership(bob);

    assertEq(
        token.owner(),
        address(this)
    );

    assertEq(
        token.pendingOwner(),
        address(0)
    );
}


function testOwnershipCanBeTransferredToNewOwnerAndUsed() public {

    token.transferOwnership(alice);

    vm.prank(alice);

    token.acceptOwnership();

    assertEq(
        token.owner(),
        alice
    );

    vm.prank(alice);

    token.pause();

    assertTrue(
        token.paused()
    );
}


// =============================================================
// BURN SECURITY
// =============================================================

function testBurnCannotExceedBalance() public {

    uint256 balance =
        token.balanceOf(liquidity);

    vm.prank(liquidity);

    vm.expectRevert();

    token.burn(
        balance + 1
    );
}


function testBurnFromCannotExceedBalance() public {

    uint256 balance =
        token.balanceOf(liquidity);

    vm.prank(liquidity);

    token.approve(
        alice,
        balance + 1
    );

    vm.prank(alice);

    vm.expectRevert();

    token.burnFrom(
        liquidity,
        balance + 1
    );
}


function testBurnDoesNotAffectOtherBalances() public {

    uint256 beforeCommunity =
        token.balanceOf(community);

    uint256 beforeTreasury =
        token.balanceOf(treasury);

    vm.prank(liquidity);

    token.burn(
        100 ether
    );

    assertEq(
        token.balanceOf(community),
        beforeCommunity
    );

    assertEq(
        token.balanceOf(treasury),
        beforeTreasury
    );
}


// =============================================================
// PERMIT SECURITY
// =============================================================

function testPermitNonceStartsAtZero() public {

    uint256 privateKey =
        0xA11CE;

    address permitOwner =
        vm.addr(privateKey);

    assertEq(
        token.nonces(permitOwner),
        0
    );
}


function testPermitCannotBeReplayed() public {

    uint256 privateKey =
        0xA11CE;

    address permitOwner =
        vm.addr(privateKey);

    uint256 amount =
        100 ether;

    uint256 deadline =
        block.timestamp + 1 days;

    vm.prank(liquidity);

    token.transfer(
        permitOwner,
        amount
    );

    uint256 nonce =
        token.nonces(permitOwner);

    bytes32 permitTypeHash =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    bytes32 structHash =
        keccak256(
            abi.encode(
                permitTypeHash,
                permitOwner,
                alice,
                amount,
                nonce,
                deadline
            )
        );

    bytes32 digest =
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash
            )
        );

    (uint8 v, bytes32 r, bytes32 s) =
        vm.sign(
            privateKey,
            digest
        );

    token.permit(
        permitOwner,
        alice,
        amount,
        deadline,
        v,
        r,
        s
    );

    assertEq(
        token.nonces(permitOwner),
        nonce + 1
    );

    vm.expectRevert();

    token.permit(
        permitOwner,
        alice,
        amount,
        deadline,
        v,
        r,
        s
    );
}


function testPermitInvalidSignatureReverts() public {

    uint256 ownerPrivateKey =
        0xA11CE;

    uint256 wrongPrivateKey =
        0xB0B;

    address permitOwner =
        vm.addr(ownerPrivateKey);

    uint256 amount =
        100 ether;

    uint256 deadline =
        block.timestamp + 1 days;

    uint256 nonce =
        token.nonces(permitOwner);

    bytes32 permitTypeHash =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    bytes32 structHash =
        keccak256(
            abi.encode(
                permitTypeHash,
                permitOwner,
                alice,
                amount,
                nonce,
                deadline
            )
        );

    bytes32 digest =
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash
            )
        );

    (
        uint8 v,
        bytes32 r,
        bytes32 s
    ) =
        vm.sign(
            wrongPrivateKey,
            digest
        );

    vm.expectRevert();

    token.permit(
        permitOwner,
        alice,
        amount,
        deadline,
        v,
        r,
        s
    );
}


function testPermitWorksWhileTokenPaused() public {

    uint256 privateKey =
        0xA11CE;

    address permitOwner =
        vm.addr(privateKey);

    uint256 amount =
        100 ether;

    uint256 deadline =
        block.timestamp + 1 days;

    vm.prank(liquidity);

    token.transfer(
        permitOwner,
        amount
    );

    token.pause();

    uint256 nonce =
        token.nonces(permitOwner);

    bytes32 permitTypeHash =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    bytes32 structHash =
        keccak256(
            abi.encode(
                permitTypeHash,
                permitOwner,
                alice,
                amount,
                nonce,
                deadline
            )
        );

    bytes32 digest =
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash
            )
        );

    (
        uint8 v,
        bytes32 r,
        bytes32 s
    ) =
        vm.sign(
            privateKey,
            digest
        );

    token.permit(
        permitOwner,
        alice,
        amount,
        deadline,
        v,
        r,
        s
    );

    assertEq(
        token.allowance(
            permitOwner,
            alice
        ),
        amount
    );
}


// =============================================================
// INVARIANTS
// =============================================================

function testTotalSupplyNeverExceedsMaxSupplyAfterBurn() public {

    uint256 beforeSupply =
        token.totalSupply();

    vm.prank(liquidity);

    token.burn(
        100 ether
    );

    assertLe(
        token.totalSupply(),
        MAX_SUPPLY
    );

    assertLt(
        token.totalSupply(),
        beforeSupply
    );
}


function testAllInitialBalancesEqualTotalSupply() public {

    uint256 total =
        token.balanceOf(liquidity)
        + token.balanceOf(community)
        + token.balanceOf(treasury)
        + token.balanceOf(team)
        + token.balanceOf(marketing)
        + token.balanceOf(reserve);

    assertEq(
        total,
        token.totalSupply()
    );
}
function testTransferRevertsWhenBalanceInsufficient() public {
    uint256 amount = LIQUIDITY_ALLOCATION + 1;

    vm.prank(liquidity);

    vm.expectRevert();

    token.transfer(
        alice,
        amount
    );
}


function testTransferFromRevertsWhenBalanceInsufficient() public {
    uint256 amount = LIQUIDITY_ALLOCATION + 1;

    vm.prank(liquidity);

    token.approve(
        alice,
        amount
    );

    vm.prank(alice);

    vm.expectRevert();

    token.transferFrom(
        liquidity,
        bob,
        amount
    );
}


function testTransferFromRevertsWhenAllowanceInsufficient() public {
    uint256 approved = 50 ether;
    uint256 amount = 100 ether;

    vm.prank(liquidity);

    token.approve(
        alice,
        approved
    );

    vm.prank(alice);

    vm.expectRevert();

    token.transferFrom(
        liquidity,
        bob,
        amount
    );
}


function testBurnRevertsWhenBalanceInsufficient() public {
    uint256 amount = LIQUIDITY_ALLOCATION + 1;

    vm.prank(liquidity);

    vm.expectRevert();

    token.burn(amount);
}


function testBurnFromRevertsWhenAllowanceInsufficient() public {
    uint256 approved = 50 ether;
    uint256 amount = 100 ether;

    vm.prank(liquidity);

    token.approve(
        alice,
        approved
    );

    vm.prank(alice);

    vm.expectRevert();

    token.burnFrom(
        liquidity,
        amount
    );
}


function testBurnFromRevertsWhenBalanceInsufficient() public {
    uint256 amount = LIQUIDITY_ALLOCATION + 1;

    vm.prank(liquidity);

    token.approve(
        alice,
        amount
    );

    vm.prank(alice);

    vm.expectRevert();

    token.burnFrom(
        liquidity,
        amount
    );
}
}