// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2ERC20.sol";

contract ApexV2ERC20Harness is ApexV2ERC20 {
    function mint(
        address to,
        uint256 value
    )
        external
    {
        _mint(to, value);
    }

    function burn(
        address from,
        uint256 value
    )
        external
    {
        _burn(from, value);
    }

    function exposedTransfer(
        address from,
        address to,
        uint256 value
    )
        external
    {
        _transfer(from, to, value);
    }
}

contract ApexV2ERC20FinalSecurityTest is Test {
    ApexV2ERC20Harness internal token;

    uint256 internal constant OWNER_PK =
        0xA11CE;

    address internal owner;
    address internal spender;
    address internal recipient;

    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 internal constant SECP256K1N =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function setUp()
        public
    {
        token =
            new ApexV2ERC20Harness();

        owner =
            vm.addr(OWNER_PK);

        spender =
            makeAddr("spender");

        recipient =
            makeAddr("recipient");

        token.mint(
            owner,
            1_000_000 ether
        );
    }

    // ============================================================
    // METADATA
    // ============================================================

    function test_metadata()
        public
        view
    {
        assertEq(
            token.name(),
            "Apex V2"
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

    // ============================================================
    // MINT
    // ============================================================

    function test_mint_updatesBalanceAndSupply()
        public
    {
        uint256 supplyBefore =
            token.totalSupply();

        uint256 balanceBefore =
            token.balanceOf(recipient);

        token.mint(
            recipient,
            100 ether
        );

        assertEq(
            token.totalSupply(),
            supplyBefore + 100 ether
        );

        assertEq(
            token.balanceOf(recipient),
            balanceBefore + 100 ether
        );
    }

    function test_mintToZeroAddress_isAllowed()
        public
    {
        uint256 supplyBefore =
            token.totalSupply();

        uint256 zeroBalanceBefore =
            token.balanceOf(address(0));

        token.mint(
            address(0),
            1000
        );

        assertEq(
            token.totalSupply(),
            supplyBefore + 1000
        );

        assertEq(
            token.balanceOf(address(0)),
            zeroBalanceBefore + 1000
        );
    }

    function test_mintZeroValue()
        public
    {
        uint256 supplyBefore =
            token.totalSupply();

        uint256 balanceBefore =
            token.balanceOf(recipient);

        token.mint(
            recipient,
            0
        );

        assertEq(
            token.totalSupply(),
            supplyBefore
        );

        assertEq(
            token.balanceOf(recipient),
            balanceBefore
        );
    }

    // ============================================================
    // BURN
    // ============================================================

    function test_burn_updatesBalanceAndSupply()
        public
    {
        uint256 amount =
            100 ether;

        uint256 supplyBefore =
            token.totalSupply();

        uint256 balanceBefore =
            token.balanceOf(owner);

        token.burn(
            owner,
            amount
        );

        assertEq(
            token.totalSupply(),
            supplyBefore - amount
        );

        assertEq(
            token.balanceOf(owner),
            balanceBefore - amount
        );
    }

    function test_burn_revertsZeroAddress()
        public
    {
        vm.expectRevert(
            ApexV2ERC20.ZeroAddress.selector
        );

        token.burn(
            address(0),
            1
        );
    }

    function test_burn_revertsInsufficientBalance()
        public
    {
        uint256 balance =
            token.balanceOf(owner);

        vm.expectRevert();

        token.burn(
            owner,
            balance + 1
        );
    }

    function test_burnZeroValue()
        public
    {
        uint256 supplyBefore =
            token.totalSupply();

        uint256 balanceBefore =
            token.balanceOf(owner);

        token.burn(
            owner,
            0
        );

        assertEq(
            token.totalSupply(),
            supplyBefore
        );

        assertEq(
            token.balanceOf(owner),
            balanceBefore
        );
    }

    // ============================================================
    // TRANSFER
    // ============================================================

    function test_transferExactBalance()
        public
    {
        uint256 balance =
            token.balanceOf(owner);

        vm.prank(owner);

        bool success =
            token.transfer(
                recipient,
                balance
            );

        assertTrue(success);

        assertEq(
            token.balanceOf(owner),
            0
        );

        assertEq(
            token.balanceOf(recipient),
            balance
        );
    }

    function test_transferZeroValue()
        public
    {
        uint256 ownerBefore =
            token.balanceOf(owner);

        uint256 recipientBefore =
            token.balanceOf(recipient);

        vm.prank(owner);

        bool success =
            token.transfer(
                recipient,
                0
            );

        assertTrue(success);

        assertEq(
            token.balanceOf(owner),
            ownerBefore
        );

        assertEq(
            token.balanceOf(recipient),
            recipientBefore
        );
    }

    function test_transfer_revertsInsufficientBalance()
        public
    {
        uint256 balance =
            token.balanceOf(owner);

        vm.prank(owner);

        vm.expectRevert();

        token.transfer(
            recipient,
            balance + 1
        );
    }

    function test_transfer_revertsZeroRecipient()
        public
    {
        vm.prank(owner);

        vm.expectRevert(
            ApexV2ERC20.ZeroAddress.selector
        );

        token.transfer(
            address(0),
            1
        );
    }

    function test_internalTransfer_revertsZeroFrom()
        public
    {
        vm.expectRevert(
            ApexV2ERC20.ZeroAddress.selector
        );

        token.exposedTransfer(
            address(0),
            recipient,
            0
        );
    }

    function test_internalTransfer_revertsZeroTo()
        public
    {
        vm.expectRevert(
            ApexV2ERC20.ZeroAddress.selector
        );

        token.exposedTransfer(
            owner,
            address(0),
            1
        );
    }

    // ============================================================
    // APPROVE
    // ============================================================

    function test_approveExactValue()
        public
    {
        vm.prank(owner);

        bool success =
            token.approve(
                spender,
                123 ether
            );

        assertTrue(success);

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            123 ether
        );
    }

    function test_approveZeroValue()
        public
    {
        vm.startPrank(owner);

        token.approve(
            spender,
            100 ether
        );

        token.approve(
            spender,
            0
        );

        vm.stopPrank();

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            0
        );
    }

    function test_approve_revertsZeroSpender()
        public
    {
        vm.prank(owner);

        vm.expectRevert(
            ApexV2ERC20.ZeroAddress.selector
        );

        token.approve(
            address(0),
            1
        );
    }

    // ============================================================
    // TRANSFER FROM
    // ============================================================

    function test_transferFrom_decreasesFiniteAllowance()
        public
    {
        vm.prank(owner);

        token.approve(
            spender,
            100 ether
        );

        vm.prank(spender);

        bool success =
            token.transferFrom(
                owner,
                recipient,
                40 ether
            );

        assertTrue(success);

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            60 ether
        );

        assertEq(
            token.balanceOf(recipient),
            40 ether
        );
    }

    function test_transferFrom_exactFiniteAllowance()
        public
    {
        vm.prank(owner);

        token.approve(
            spender,
            100 ether
        );

        vm.prank(spender);

        token.transferFrom(
            owner,
            recipient,
            100 ether
        );

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            0
        );

        assertEq(
            token.balanceOf(recipient),
            100 ether
        );
    }

    function test_transferFrom_infiniteAllowanceDoesNotDecrease()
        public
    {
        vm.prank(owner);

        token.approve(
            spender,
            type(uint256).max
        );

        vm.prank(spender);

        token.transferFrom(
            owner,
            recipient,
            100 ether
        );

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            type(uint256).max
        );

        assertEq(
            token.balanceOf(recipient),
            100 ether
        );
    }

    function test_transferFrom_revertsAllowanceTooLow()
        public
    {
        vm.prank(owner);

        token.approve(
            spender,
            10 ether
        );

        vm.prank(spender);

        vm.expectRevert();

        token.transferFrom(
            owner,
            recipient,
            11 ether
        );
    }

    function test_transferFrom_revertsBalanceTooLow()
        public
    {
        uint256 ownerBalance =
            token.balanceOf(owner);

        vm.prank(owner);

        token.approve(
            spender,
            type(uint256).max
        );

        vm.prank(spender);

        vm.expectRevert();

        token.transferFrom(
            owner,
            recipient,
            ownerBalance + 1
        );
    }

    function test_transferFrom_revertsZeroRecipient()
        public
    {
        vm.prank(owner);

        token.approve(
            spender,
            100 ether
        );

        vm.prank(spender);

        vm.expectRevert(
            ApexV2ERC20.ZeroAddress.selector
        );

        token.transferFrom(
            owner,
            address(0),
            1 ether
        );
    }

    // ============================================================
    // DOMAIN SEPARATOR
    // ============================================================

    function test_domainSeparator_initialChain()
        public
        view
    {
        assertEq(
            token.DOMAIN_SEPARATOR(),
            token.INITIAL_DOMAIN_SEPARATOR()
        );

        assertEq(
            token.INITIAL_CHAIN_ID(),
            block.chainid
        );
    }

    function test_domainSeparator_changesWithChainId()
        public
    {
        bytes32 initial =
            token.DOMAIN_SEPARATOR();

        uint256 initialChainId =
            token.INITIAL_CHAIN_ID();

        vm.chainId(
            initialChainId + 1
        );

        bytes32 changed =
            token.DOMAIN_SEPARATOR();

        assertNotEq(
            changed,
            initial
        );

        assertEq(
            token.INITIAL_DOMAIN_SEPARATOR(),
            initial
        );

        assertEq(
            token.INITIAL_CHAIN_ID(),
            initialChainId
        );
    }
    // ============================================================
    // PERMIT
    // ============================================================

    function test_permit_success()
        public
    {
        uint256 value =
            500 ether;

        uint256 deadline =
            block.timestamp + 1 days;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                OWNER_PK,
                owner,
                spender,
                value,
                deadline
            );

        token.permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            value
        );

        assertEq(
            token.nonces(owner),
            1
        );
    }

    function test_permit_deadlineExactlyNowSucceeds()
        public
    {
        uint256 value =
            100 ether;

        uint256 deadline =
            block.timestamp;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                OWNER_PK,
                owner,
                spender,
                value,
                deadline
            );

        token.permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            value
        );

        assertEq(
            token.nonces(owner),
            1
        );
    }

    function test_permit_revertsExpired()
        public
    {
        vm.warp(100);

        uint256 deadline =
            99;

        vm.expectRevert(
            ApexV2ERC20.ExpiredPermit.selector
        );

        token.permit(
            owner,
            spender,
            1,
            deadline,
            27,
            bytes32(0),
            bytes32(0)
        );
    }

    function test_permit_revertsZeroOwner()
        public
    {
        vm.expectRevert(
            ApexV2ERC20.ZeroAddress.selector
        );

        token.permit(
            address(0),
            spender,
            1,
            block.timestamp + 1,
            27,
            bytes32(0),
            bytes32(0)
        );
    }

    function test_permit_revertsZeroSpender()
        public
    {
        vm.expectRevert(
            ApexV2ERC20.ZeroAddress.selector
        );

        token.permit(
            owner,
            address(0),
            1,
            block.timestamp + 1,
            27,
            bytes32(0),
            bytes32(0)
        );
    }

    function test_permit_revertsInvalidV_0()
        public
    {
        vm.expectRevert(
            ApexV2ERC20.InvalidSignature.selector
        );

        token.permit(
            owner,
            spender,
            1,
            block.timestamp + 1,
            0,
            bytes32(uint256(1)),
            bytes32(uint256(1))
        );
    }

    function test_permit_revertsInvalidV_29()
        public
    {
        vm.expectRevert(
            ApexV2ERC20.InvalidSignature.selector
        );

        token.permit(
            owner,
            spender,
            1,
            block.timestamp + 1,
            29,
            bytes32(uint256(1)),
            bytes32(uint256(1))
        );
    }

    function test_permit_revertsHighS()
        public
    {
        uint256 value =
            100 ether;

        uint256 deadline =
            block.timestamp + 1 days;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                OWNER_PK,
                owner,
                spender,
                value,
                deadline
            );

        bytes32 highS =
            bytes32(
                SECP256K1N -
                uint256(s)
            );

        uint8 malleableV =
            v == 27
                ? 28
                : 27;

        vm.expectRevert(
            ApexV2ERC20.InvalidSignature.selector
        );

        token.permit(
            owner,
            spender,
            value,
            deadline,
            malleableV,
            r,
            highS
        );

        assertEq(
            token.nonces(owner),
            0
        );

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            0
        );
    }

    function test_permit_revertsWrongSigner()
        public
    {
        uint256 attackerPk =
            0xB0B;

        uint256 value =
            100 ether;

        uint256 deadline =
            block.timestamp + 1 days;

        bytes32 digest =
            _permitDigest(
                owner,
                spender,
                value,
                token.nonces(owner),
                deadline
            );

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            vm.sign(
                attackerPk,
                digest
            );

        vm.expectRevert(
            ApexV2ERC20.InvalidSignature.selector
        );

        token.permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.nonces(owner),
            0
        );
    }

    function test_permit_revertsZeroRecoveredAddress()
        public
    {
        vm.expectRevert(
            ApexV2ERC20.InvalidSignature.selector
        );

        token.permit(
            owner,
            spender,
            1,
            block.timestamp + 1 days,
            27,
            bytes32(0),
            bytes32(0)
        );

        assertEq(
            token.nonces(owner),
            0
        );
    }

    function test_permit_cannotReplay()
        public
    {
        uint256 value =
            100 ether;

        uint256 deadline =
            block.timestamp + 1 days;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                OWNER_PK,
                owner,
                spender,
                value,
                deadline
            );

        token.permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.nonces(owner),
            1
        );

        vm.expectRevert(
            ApexV2ERC20.InvalidSignature.selector
        );

        token.permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.nonces(owner),
            1
        );
    }

    function test_permit_nonceIncrementsExactlyOnce()
        public
    {
        uint256 deadline =
            block.timestamp + 1 days;

        (
            uint8 v0,
            bytes32 r0,
            bytes32 s0
        ) =
            _signPermit(
                OWNER_PK,
                owner,
                spender,
                100,
                deadline
            );

        token.permit(
            owner,
            spender,
            100,
            deadline,
            v0,
            r0,
            s0
        );

        assertEq(
            token.nonces(owner),
            1
        );

        (
            uint8 v1,
            bytes32 r1,
            bytes32 s1
        ) =
            _signPermit(
                OWNER_PK,
                owner,
                spender,
                200,
                deadline
            );

        token.permit(
            owner,
            spender,
            200,
            deadline,
            v1,
            r1,
            s1
        );

        assertEq(
            token.nonces(owner),
            2
        );

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            200
        );
    }

    function test_permit_signatureCannotBeUsedAfterChainIdChange()
        public
    {
        uint256 value =
            100 ether;

        uint256 deadline =
            block.timestamp + 1 days;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                OWNER_PK,
                owner,
                spender,
                value,
                deadline
            );

        vm.chainId(
            block.chainid + 1
        );

        vm.expectRevert(
            ApexV2ERC20.InvalidSignature.selector
        );

        token.permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.nonces(owner),
            0
        );
    }

    function test_permit_newChainIdSignatureSucceeds()
        public
    {
        vm.chainId(
            block.chainid + 1
        );

        uint256 value =
            100 ether;

        uint256 deadline =
            block.timestamp + 1 days;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) =
            _signPermit(
                OWNER_PK,
                owner,
                spender,
                value,
                deadline
            );

        token.permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            value
        );

        assertEq(
            token.nonces(owner),
            1
        );
    }

    // ============================================================
    // FUZZ
    // ============================================================

    function testFuzz_transfer(
        uint96 rawAmount
    )
        public
    {
        uint256 ownerBalance =
            token.balanceOf(owner);

        uint256 amount =
            bound(
                uint256(rawAmount),
                0,
                ownerBalance
            );

        uint256 supplyBefore =
            token.totalSupply();

        vm.prank(owner);

        token.transfer(
            recipient,
            amount
        );

        assertEq(
            token.balanceOf(owner),
            ownerBalance - amount
        );

        assertEq(
            token.balanceOf(recipient),
            amount
        );

        assertEq(
            token.totalSupply(),
            supplyBefore
        );
    }

    function testFuzz_transferFromFiniteAllowance(
        uint96 rawAllowance,
        uint96 rawAmount
    )
        public
    {
        uint256 ownerBalance =
            token.balanceOf(owner);

        uint256 approved =
            bound(
                uint256(rawAllowance),
                0,
                ownerBalance
            );

        uint256 amount =
            bound(
                uint256(rawAmount),
                0,
                approved
            );

        vm.prank(owner);

        token.approve(
            spender,
            approved
        );

        vm.prank(spender);

        token.transferFrom(
            owner,
            recipient,
            amount
        );

        assertEq(
            token.allowance(
                owner,
                spender
            ),
            approved - amount
        );

        assertEq(
            token.balanceOf(recipient),
            amount
        );
    }

    function testFuzz_mintBurnAccounting(
        uint96 rawAmount
    )
        public
    {
        uint256 amount =
            uint256(rawAmount);

        uint256 supplyBefore =
            token.totalSupply();

        token.mint(
            recipient,
            amount
        );

        assertEq(
            token.totalSupply(),
            supplyBefore + amount
        );

        assertEq(
            token.balanceOf(recipient),
            amount
        );

        token.burn(
            recipient,
            amount
        );

        assertEq(
            token.totalSupply(),
            supplyBefore
        );

        assertEq(
            token.balanceOf(recipient),
            0
        );
    }

    // ============================================================
    // HELPERS
    // ============================================================

    function _signPermit(
        uint256 privateKey,
        address permitOwner,
        address permitSpender,
        uint256 value,
        uint256 deadline
    )
        internal
        view
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        bytes32 digest =
            _permitDigest(
                permitOwner,
                permitSpender,
                value,
                token.nonces(permitOwner),
                deadline
            );

        return
            vm.sign(
                privateKey,
                digest
            );
    }

    function _permitDigest(
        address permitOwner,
        address permitSpender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    permitOwner,
                    permitSpender,
                    value,
                    nonce,
                    deadline
                )
            );

        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    structHash
                )
            );
    }
}