// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";

contract ApexV2ERC20SecurityTest is Test {
    ApexV2Pair pair;

    MockERC20 token0;
    MockERC20 token1;

    MockFactory factory;

    address user = address(0x111);

    address spender = address(0x222);

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");

        token1 = new MockERC20("Token1", "TK1");

        factory = new MockFactory();

        pair = ApexV2Pair(factory.createPair(address(token0), address(token1)));

        token0.mint(address(this), 10000 ether);

        token1.mint(address(this), 10000 ether);

        token0.transfer(address(pair), 1000 ether);

        token1.transfer(address(pair), 1000 ether);

        pair.mint(address(this));
    }

    // =============================================================
    // TRANSFER
    // =============================================================

    function testTransferWorks() public {
        uint256 amount = 100 ether;

        uint256 before = pair.balanceOf(user);

        pair.transfer(user, amount);

        uint256 afterBalance = pair.balanceOf(user);

        assertEq(afterBalance - before, amount);
    }

    function testTransferToZeroAddressFails() public {
        vm.expectRevert(ApexV2ERC20.ZeroAddress.selector);

        pair.transfer(address(0), 100 ether);
    }

    // =============================================================
    // APPROVAL
    // =============================================================

    function testApproveAndTransferFrom() public {
        uint256 amount = 100 ether;

        pair.approve(spender, amount);

        assertEq(pair.allowance(address(this), spender), amount);

        vm.prank(spender);

        pair.transferFrom(address(this), user, amount);

        assertEq(pair.balanceOf(user), amount);

        assertEq(pair.allowance(address(this), spender), 0);
    }

    function testApproveZeroAddressFails() public {
        vm.expectRevert(ApexV2ERC20.ZeroAddress.selector);

        pair.approve(address(0), 100 ether);
    }

    function testInfiniteApprovalDoesNotDecrease() public {
        pair.approve(spender, type(uint256).max);

        vm.prank(spender);

        pair.transferFrom(address(this), user, 100 ether);

        assertEq(pair.allowance(address(this), spender), type(uint256).max);
    }

    function testTransferFromWithoutAllowanceFails() public {
        vm.prank(spender);

        vm.expectRevert();

        pair.transferFrom(address(this), user, 100 ether);
    }

    // =============================================================
    // TOTAL SUPPLY
    // =============================================================

    function testTotalSupplyMatchesBalances() public view {
        uint256 supply = pair.totalSupply();

        uint256 balance0 = pair.balanceOf(address(this));

        uint256 burned = pair.balanceOf(address(0));

        assertEq(supply, balance0 + burned);
    }

    // =============================================================
    // DOMAIN SEPARATOR
    // =============================================================

    function testDomainSeparatorUsesInitialValueOnSameChain() public view {
        bytes32 initialSeparator = pair.INITIAL_DOMAIN_SEPARATOR();

        bytes32 currentSeparator = pair.DOMAIN_SEPARATOR();

        assertEq(currentSeparator, initialSeparator);
    }

    function testDomainSeparatorChangesWhenChainIdChanges() public {
        bytes32 initialSeparator = pair.INITIAL_DOMAIN_SEPARATOR();

        uint256 initialChainId = pair.INITIAL_CHAIN_ID();

        vm.chainId(initialChainId + 1);

        bytes32 newSeparator = pair.DOMAIN_SEPARATOR();

        assertTrue(newSeparator != initialSeparator);
    }

    // =============================================================
    // PERMIT
    // =============================================================

    function testPermitExpiredFails() public {
        uint256 privateKey = 123;

        address owner = vm.addr(privateKey);

        vm.expectRevert(ApexV2ERC20.ExpiredPermit.selector);

        pair.permit(owner, spender, 100 ether, block.timestamp - 1, 27, bytes32(0), bytes32(0));
    }

    function testPermitZeroOwnerFails() public {
        vm.expectRevert(ApexV2ERC20.ZeroAddress.selector);

        pair.permit(address(0), spender, 100 ether, block.timestamp + 1 days, 27, bytes32(0), bytes32(0));
    }

    function testPermitZeroSpenderFails() public {
        uint256 privateKey = 123;

        address owner = vm.addr(privateKey);

        vm.expectRevert(ApexV2ERC20.ZeroAddress.selector);

        pair.permit(owner, address(0), 100 ether, block.timestamp + 1 days, 27, bytes32(0), bytes32(0));
    }

    function testPermitInvalidSignatureFails() public {
        uint256 privateKey = 123;

        address owner = vm.addr(privateKey);

        vm.expectRevert(ApexV2ERC20.InvalidSignature.selector);

        pair.permit(owner, spender, 100 ether, block.timestamp + 1 days, 27, bytes32(0), bytes32(0));
    }

    function testPermitWorks() public {
        uint256 privateKey = 123;

        address owner = vm.addr(privateKey);

        uint256 value = 100 ether;

        uint256 deadline = block.timestamp + 1 days;

        uint256 nonce = pair.nonces(owner);

        bytes32 structHash = keccak256(abi.encode(pair.PERMIT_TYPEHASH(), owner, spender, value, nonce, deadline));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", pair.DOMAIN_SEPARATOR(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        pair.permit(owner, spender, value, deadline, v, r, s);

        assertEq(pair.allowance(owner, spender), value);

        assertEq(pair.nonces(owner), nonce + 1);
    }

    function testPermitCannotBeReplayed() public {
        uint256 privateKey = 123;

        address owner = vm.addr(privateKey);

        uint256 value = 100 ether;

        uint256 deadline = block.timestamp + 1 days;

        uint256 nonce = pair.nonces(owner);

        bytes32 structHash = keccak256(abi.encode(pair.PERMIT_TYPEHASH(), owner, spender, value, nonce, deadline));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", pair.DOMAIN_SEPARATOR(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        pair.permit(owner, spender, value, deadline, v, r, s);

        assertEq(pair.nonces(owner), 1);

        vm.expectRevert(ApexV2ERC20.InvalidSignature.selector);

        pair.permit(owner, spender, value, deadline, v, r, s);
    }
}
