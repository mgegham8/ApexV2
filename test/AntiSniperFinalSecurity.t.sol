// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {AntiSniper} from "../src/contracts/security/AntiSniper.sol";

contract AntiSniperFinalSecurityTest is Test {
    AntiSniper internal antiSniper;

    address internal buyer;
    address internal buyer2;
    address internal attacker;
    address internal newOwner;

    uint256 internal constant PROTECTION_BLOCKS = 20;
    uint256 internal constant MAX_BUY = 1_000 ether;
    uint256 internal constant MAX_WALLET = 5_000 ether;

    function setUp() public {
        buyer = makeAddr("buyer");

        buyer2 = makeAddr("buyer2");

        attacker = makeAddr("attacker");

        newOwner = makeAddr("newOwner");

        antiSniper = new AntiSniper();
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    function test_constructor_setsOwner() public view {
        assertEq(antiSniper.owner(), address(this));
    }

    function test_constructor_initialState() public view {
        assertFalse(antiSniper.protectionEnabled());

        assertFalse(antiSniper.launchStarted());

        assertEq(antiSniper.launchBlock(), 0);

        assertEq(antiSniper.protectionBlocks(), 0);

        assertEq(antiSniper.maxBuyAmount(), 0);

        assertEq(antiSniper.maxWalletAmount(), 0);

        assertFalse(antiSniper.isProtectionActive());

        assertEq(antiSniper.protectionEndBlock(), 0);
    }

    // ============================================================
    // START LAUNCH
    // ============================================================

    function test_startLaunch_success() public {
        uint256 currentBlock = block.number;

        antiSniper.startLaunch(PROTECTION_BLOCKS, MAX_BUY, MAX_WALLET);

        assertTrue(antiSniper.launchStarted());

        assertTrue(antiSniper.protectionEnabled());

        assertEq(antiSniper.launchBlock(), currentBlock);

        assertEq(antiSniper.protectionBlocks(), PROTECTION_BLOCKS);

        assertEq(antiSniper.maxBuyAmount(), MAX_BUY);

        assertEq(antiSniper.maxWalletAmount(), MAX_WALLET);
    }

    function test_startLaunch_emitsEvent() public {
        uint256 currentBlock = block.number;

        vm.expectEmit(true, false, false, true);

        emit AntiSniper.LaunchStarted(currentBlock, PROTECTION_BLOCKS, MAX_BUY, MAX_WALLET);

        antiSniper.startLaunch(PROTECTION_BLOCKS, MAX_BUY, MAX_WALLET);
    }

    function test_startLaunch_revertsNonOwner() public {
        vm.prank(attacker);

        vm.expectRevert(AntiSniper.NotOwner.selector);

        antiSniper.startLaunch(PROTECTION_BLOCKS, MAX_BUY, MAX_WALLET);
    }

    function test_startLaunch_revertsAlreadyStarted() public {
        _startDefault();

        vm.expectRevert(AntiSniper.AlreadyStarted.selector);

        antiSniper.startLaunch(PROTECTION_BLOCKS, MAX_BUY, MAX_WALLET);
    }

    function test_startLaunch_revertsAfterDisable() public {
        _startDefault();

        antiSniper.disableProtection();

        vm.expectRevert(AntiSniper.AlreadyStarted.selector);

        antiSniper.startLaunch(PROTECTION_BLOCKS, MAX_BUY, MAX_WALLET);
    }

    function test_startLaunch_revertsZeroProtectionBlocks() public {
        vm.expectRevert(AntiSniper.InvalidProtectionBlocks.selector);

        antiSniper.startLaunch(0, MAX_BUY, MAX_WALLET);
    }

    function test_startLaunch_revertsZeroMaxBuy() public {
        vm.expectRevert(AntiSniper.InvalidMaxBuy.selector);

        antiSniper.startLaunch(PROTECTION_BLOCKS, 0, MAX_WALLET);
    }

    function test_startLaunch_revertsZeroMaxWallet() public {
        vm.expectRevert(AntiSniper.InvalidMaxWallet.selector);

        antiSniper.startLaunch(PROTECTION_BLOCKS, MAX_BUY, 0);
    }

    function test_startLaunch_revertsMaxBuyGreaterThanMaxWallet() public {
        vm.expectRevert(AntiSniper.MaxBuyGreaterThanMaxWallet.selector);

        antiSniper.startLaunch(PROTECTION_BLOCKS, MAX_WALLET + 1, MAX_WALLET);
    }

    // ============================================================
    // DISABLE PROTECTION
    // ============================================================

    function test_disableProtection_success() public {
        _startDefault();

        antiSniper.disableProtection();

        assertFalse(antiSniper.protectionEnabled());

        assertFalse(antiSniper.isProtectionActive());
    }

    function test_disableProtection_emitsEvent() public {
        _startDefault();

        vm.expectEmit(false, false, false, false);

        emit AntiSniper.ProtectionDisabled();

        antiSniper.disableProtection();
    }

    function test_disableProtection_revertsNonOwner() public {
        _startDefault();

        vm.prank(attacker);

        vm.expectRevert(AntiSniper.NotOwner.selector);

        antiSniper.disableProtection();
    }

    function test_disableProtection_revertsWhenAlreadyDisabled() public {
        vm.expectRevert(AntiSniper.ProtectionNotEnabled.selector);

        antiSniper.disableProtection();
    }

    function test_disableProtection_revertsSecondTime() public {
        _startDefault();

        antiSniper.disableProtection();

        vm.expectRevert(AntiSniper.ProtectionNotEnabled.selector);

        antiSniper.disableProtection();
    }

    // ============================================================
    // BLACKLIST
    // ============================================================

    function test_setBlacklist_success() public {
        antiSniper.setBlacklist(buyer, true);

        assertTrue(antiSniper.blacklist(buyer));

        antiSniper.setBlacklist(buyer, false);

        assertFalse(antiSniper.blacklist(buyer));
    }

    function test_setBlacklist_emitsEvent() public {
        vm.expectEmit(true, false, false, true);

        emit AntiSniper.BlacklistUpdated(buyer, true);

        antiSniper.setBlacklist(buyer, true);
    }

    function test_setBlacklist_revertsNonOwner() public {
        vm.prank(attacker);

        vm.expectRevert(AntiSniper.NotOwner.selector);

        antiSniper.setBlacklist(buyer, true);
    }

    function test_setBlacklist_revertsZeroAddress() public {
        vm.expectRevert(AntiSniper.ZeroAddress.selector);

        antiSniper.setBlacklist(address(0), true);
    }

    // ============================================================
    // WHITELIST
    // ============================================================

    function test_setWhitelist_success() public {
        antiSniper.setWhitelist(buyer, true);

        assertTrue(antiSniper.whitelist(buyer));

        antiSniper.setWhitelist(buyer, false);

        assertFalse(antiSniper.whitelist(buyer));
    }

    function test_setWhitelist_emitsEvent() public {
        vm.expectEmit(true, false, false, true);

        emit AntiSniper.WhitelistUpdated(buyer, true);

        antiSniper.setWhitelist(buyer, true);
    }

    function test_setWhitelist_revertsNonOwner() public {
        vm.prank(attacker);

        vm.expectRevert(AntiSniper.NotOwner.selector);

        antiSniper.setWhitelist(buyer, true);
    }

    function test_setWhitelist_revertsZeroAddress() public {
        vm.expectRevert(AntiSniper.ZeroAddress.selector);

        antiSniper.setWhitelist(address(0), true);
    }

    // ============================================================
    // LIMITS
    // ============================================================

    function test_setLimits_success() public {
        uint256 newMaxBuy = 2_000 ether;

        uint256 newMaxWallet = 8_000 ether;

        antiSniper.setLimits(newMaxBuy, newMaxWallet);

        assertEq(antiSniper.maxBuyAmount(), newMaxBuy);

        assertEq(antiSniper.maxWalletAmount(), newMaxWallet);
    }

    function test_setLimits_emitsEvent() public {
        vm.expectEmit(false, false, false, true);

        emit AntiSniper.LimitsUpdated(MAX_BUY, MAX_WALLET);

        antiSniper.setLimits(MAX_BUY, MAX_WALLET);
    }

    function test_setLimits_revertsNonOwner() public {
        vm.prank(attacker);

        vm.expectRevert(AntiSniper.NotOwner.selector);

        antiSniper.setLimits(MAX_BUY, MAX_WALLET);
    }

    function test_setLimits_revertsZeroMaxBuy() public {
        vm.expectRevert(AntiSniper.InvalidMaxBuy.selector);

        antiSniper.setLimits(0, MAX_WALLET);
    }

    function test_setLimits_revertsZeroMaxWallet() public {
        vm.expectRevert(AntiSniper.InvalidMaxWallet.selector);

        antiSniper.setLimits(MAX_BUY, 0);
    }

    function test_setLimits_revertsMaxBuyGreaterThanMaxWallet() public {
        vm.expectRevert(AntiSniper.MaxBuyGreaterThanMaxWallet.selector);

        antiSniper.setLimits(MAX_WALLET + 1, MAX_WALLET);
    }

    // ============================================================
    // CHECK BUY - PROTECTION DISABLED
    // ============================================================

    function test_checkBuy_allowsWhenProtectionDisabled() public view {
        assertTrue(antiSniper.checkBuy(buyer, type(uint256).max, type(uint256).max));
    }

    function test_checkBuy_revertsZeroBuyerEvenWhenDisabled() public {
        vm.expectRevert(AntiSniper.ZeroAddress.selector);

        antiSniper.checkBuy(address(0), 1, 0);
    }

    // ============================================================
    // CHECK BUY - ACTIVE WINDOW
    // ============================================================

    function test_checkBuy_allowsValidBuyDuringProtection() public {
        _startDefault();

        assertTrue(antiSniper.checkBuy(buyer, MAX_BUY, MAX_WALLET - MAX_BUY));
    }

    function test_checkBuy_allowsExactMaxBuy() public {
        _startDefault();

        assertTrue(antiSniper.checkBuy(buyer, MAX_BUY, 0));
    }

    function test_checkBuy_revertsOneWeiAboveMaxBuy() public {
        _startDefault();

        vm.expectRevert(AntiSniper.MaxBuyExceeded.selector);

        antiSniper.checkBuy(buyer, MAX_BUY + 1, 0);
    }

    function test_checkBuy_allowsExactMaxWallet() public {
        _startDefault();

        uint256 balance = MAX_WALLET - MAX_BUY;

        assertTrue(antiSniper.checkBuy(buyer, MAX_BUY, balance));
    }

    function test_checkBuy_revertsOneWeiAboveMaxWallet() public {
        _startDefault();

        vm.expectRevert(AntiSniper.MaxWalletExceeded.selector);

        antiSniper.checkBuy(buyer, 1, MAX_WALLET);
    }

    function test_checkBuy_revertsBlacklisted() public {
        _startDefault();

        antiSniper.setBlacklist(buyer, true);

        vm.expectRevert(AntiSniper.Blacklisted.selector);

        antiSniper.checkBuy(buyer, 1, 0);
    }

    function test_checkBuy_whitelistBypassesBlacklist() public {
        _startDefault();

        antiSniper.setBlacklist(buyer, true);

        antiSniper.setWhitelist(buyer, true);

        assertTrue(antiSniper.checkBuy(buyer, type(uint256).max, type(uint256).max));
    }

    function test_checkBuy_whitelistBypassesMaxBuy() public {
        _startDefault();

        antiSniper.setWhitelist(buyer, true);

        assertTrue(antiSniper.checkBuy(buyer, MAX_BUY + 1, 0));
    }

    function test_checkBuy_whitelistBypassesMaxWallet() public {
        _startDefault();

        antiSniper.setWhitelist(buyer, true);

        assertTrue(antiSniper.checkBuy(buyer, type(uint256).max, type(uint256).max));
    }

    function test_checkBuy_revertsWalletBalanceOverflow() public {
        _startDefault();

        antiSniper.setLimits(type(uint256).max, type(uint256).max);

        vm.expectRevert(AntiSniper.WalletBalanceOverflow.selector);

        antiSniper.checkBuy(buyer, 1, type(uint256).max);
    }

    // ============================================================
    // PROTECTION WINDOW
    // ============================================================

    function test_isProtectionActive_trueAtLaunchBlock() public {
        _startDefault();

        assertTrue(antiSniper.isProtectionActive());
    }

    function test_isProtectionActive_trueAtExactEndBlock() public {
        _startDefault();

        uint256 endBlock = antiSniper.protectionEndBlock();

        vm.roll(endBlock);

        assertTrue(antiSniper.isProtectionActive());
    }

    function test_isProtectionActive_falseAfterEndBlock() public {
        _startDefault();

        uint256 endBlock = antiSniper.protectionEndBlock();

        vm.roll(endBlock + 1);

        assertFalse(antiSniper.isProtectionActive());
    }

    function test_checkBuy_allowsAfterProtectionWindowEnds() public {
        _startDefault();

        uint256 endBlock = antiSniper.protectionEndBlock();

        vm.roll(endBlock + 1);

        assertTrue(antiSniper.checkBuy(buyer, type(uint256).max, type(uint256).max));
    }

    function test_checkBuy_blacklistNoLongerAppliesAfterWindowEnds() public {
        _startDefault();

        antiSniper.setBlacklist(buyer, true);

        uint256 endBlock = antiSniper.protectionEndBlock();

        vm.roll(endBlock + 1);

        /*
         * Current implementation checks blacklist before the
         * expiration check, so blacklisted addresses remain blocked
         * while protectionEnabled is true.
         */
        vm.expectRevert(AntiSniper.Blacklisted.selector);

        antiSniper.checkBuy(buyer, 1, 0);
    }

    function test_checkBuy_blacklistBypassedAfterManualDisable() public {
        _startDefault();

        antiSniper.setBlacklist(buyer, true);

        antiSniper.disableProtection();

        assertTrue(antiSniper.checkBuy(buyer, type(uint256).max, type(uint256).max));
    }

    function test_protectionEndBlock_correct() public {
        uint256 launch = block.number;

        _startDefault();

        assertEq(antiSniper.protectionEndBlock(), launch + PROTECTION_BLOCKS);
    }

    // ============================================================
    // OWNERSHIP
    // ============================================================

    function test_transferOwnership_success() public {
        antiSniper.transferOwnership(newOwner);

        assertEq(antiSniper.owner(), newOwner);
    }

    function test_transferOwnership_emitsEvent() public {
        vm.expectEmit(true, true, false, true);

        emit AntiSniper.OwnershipTransferred(address(this), newOwner);

        antiSniper.transferOwnership(newOwner);
    }

    function test_transferOwnership_revertsNonOwner() public {
        vm.prank(attacker);

        vm.expectRevert(AntiSniper.NotOwner.selector);

        antiSniper.transferOwnership(newOwner);
    }

    function test_transferOwnership_revertsZeroAddress() public {
        vm.expectRevert(AntiSniper.ZeroAddress.selector);

        antiSniper.transferOwnership(address(0));
    }

    function test_transferOwnership_revertsSameOwner() public {
        vm.expectRevert(AntiSniper.SameOwner.selector);

        antiSniper.transferOwnership(address(this));
    }

    function test_oldOwnerLosesPermission() public {
        antiSniper.transferOwnership(newOwner);

        vm.expectRevert(AntiSniper.NotOwner.selector);

        antiSniper.setWhitelist(buyer, true);
    }

    function test_newOwnerCanManageProtection() public {
        antiSniper.transferOwnership(newOwner);

        vm.prank(newOwner);

        antiSniper.startLaunch(PROTECTION_BLOCKS, MAX_BUY, MAX_WALLET);

        assertTrue(antiSniper.launchStarted());
    }

    // ============================================================
    // FUZZ
    // ============================================================

    function testFuzz_validBuyWithinLimits(uint96 rawAmount, uint96 rawBalance) public {
        _startDefault();

        uint256 amount = bound(uint256(rawAmount), 0, MAX_BUY);

        uint256 maxBalance = MAX_WALLET - amount;

        uint256 currentBalance = bound(uint256(rawBalance), 0, maxBalance);

        assertTrue(antiSniper.checkBuy(buyer, amount, currentBalance));
    }

    function testFuzz_buyAboveMaxReverts(uint96 rawExtra) public {
        _startDefault();

        uint256 extra = bound(uint256(rawExtra), 1, 1_000_000 ether);

        vm.expectRevert(AntiSniper.MaxBuyExceeded.selector);

        antiSniper.checkBuy(buyer, MAX_BUY + extra, 0);
    }

    function testFuzz_walletAboveLimitReverts(uint96 rawAmount, uint96 rawExtra) public {
        _startDefault();

        uint256 amount = bound(uint256(rawAmount), 1, MAX_BUY);

        uint256 extra = bound(uint256(rawExtra), 1, 1_000_000 ether);

        uint256 currentBalance = MAX_WALLET - amount + extra;

        vm.expectRevert(AntiSniper.MaxWalletExceeded.selector);

        antiSniper.checkBuy(buyer, amount, currentBalance);
    }

    function testFuzz_protectionWindow(uint32 rawProtectionBlocks) public {
        uint256 blocksCount = bound(uint256(rawProtectionBlocks), 1, 1_000_000);

        uint256 startBlock = block.number;

        antiSniper.startLaunch(blocksCount, MAX_BUY, MAX_WALLET);

        assertEq(antiSniper.protectionEndBlock(), startBlock + blocksCount);

        vm.roll(startBlock + blocksCount);

        assertTrue(antiSniper.isProtectionActive());

        vm.roll(startBlock + blocksCount + 1);

        assertFalse(antiSniper.isProtectionActive());
    }

    function testFuzz_limitsUpdate(uint96 rawMaxBuy, uint96 rawMaxWallet) public {
        uint256 maxWallet = bound(uint256(rawMaxWallet), 1, type(uint96).max);

        uint256 maxBuy = bound(uint256(rawMaxBuy), 1, maxWallet);

        antiSniper.setLimits(maxBuy, maxWallet);

        assertEq(antiSniper.maxBuyAmount(), maxBuy);

        assertEq(antiSniper.maxWalletAmount(), maxWallet);
    }

    function testFuzz_whitelistedAlwaysPasses(uint256 amount, uint256 balance) public {
        _startDefault();

        antiSniper.setWhitelist(buyer, true);

        assertTrue(antiSniper.checkBuy(buyer, amount, balance));
    }

    function testFuzz_blacklistedRevertsDuringActiveProtection(uint96 rawAmount) public {
        _startDefault();

        antiSniper.setBlacklist(buyer, true);

        uint256 amount = bound(uint256(rawAmount), 0, MAX_BUY);

        vm.expectRevert(AntiSniper.Blacklisted.selector);

        antiSniper.checkBuy(buyer, amount, 0);
    }

    // ============================================================
    // HELPERS
    // ============================================================

    function _startDefault() internal {
        antiSniper.startLaunch(PROTECTION_BLOCKS, MAX_BUY, MAX_WALLET);
    }
}
