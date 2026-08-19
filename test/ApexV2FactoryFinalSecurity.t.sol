// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Factory.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";

contract ApexV2FactoryFinalSecurityTest is Test {
    ApexV2Factory internal factory;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;
    MockERC20 internal tokenC;

    address internal constant SETTER = address(0xA11CE);
    address internal constant NEW_SETTER = address(0xB0B);
    address internal constant ATTACKER = address(0xBAD);
    address internal constant FEE_TO = address(0xFEE);

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256 pairCount
    );

    event FeeToUpdated(
        address indexed previousFeeTo,
        address indexed newFeeTo
    );

    event FeeToSetterUpdated(
        address indexed previousFeeToSetter,
        address indexed newFeeToSetter
    );

    function setUp() public {
        factory = new ApexV2Factory(
            SETTER
        );

        tokenA = new MockERC20(
            "Token A",
            "TKA"
        );

        tokenB = new MockERC20(
            "Token B",
            "TKB"
        );

        tokenC = new MockERC20(
            "Token C",
            "TKC"
        );
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    function test_constructor_setsFeeToSetter()
        public
        view
    {
        assertEq(
            factory.feeToSetter(),
            SETTER
        );
    }

    function test_constructor_feeToStartsZero()
        public
        view
    {
        assertEq(
            factory.feeTo(),
            address(0)
        );
    }

    function test_constructor_revertsZeroSetter()
        public
    {
        vm.expectRevert(
            bytes(
                "ZERO_SETTER"
            )
        );

        new ApexV2Factory(
            address(0)
        );
    }

    // ============================================================
    // CREATE PAIR
    // ============================================================

    function test_createPair_success()
        public
    {
        address pair =
            factory.createPair(
                address(tokenA),
                address(tokenB)
            );

        assertTrue(
            pair != address(0)
        );

        assertEq(
            factory.getPair(
                address(tokenA),
                address(tokenB)
            ),
            pair
        );

        assertEq(
            factory.getPair(
                address(tokenB),
                address(tokenA)
            ),
            pair
        );

        assertEq(
            factory.allPairsLength(),
            1
        );

        assertEq(
            factory.allPairs(0),
            pair
        );
    }

    function test_createPair_revertsIdenticalTokens()
        public
    {
        vm.expectRevert(
            bytes(
                "IDENTICAL_ADDRESSES"
            )
        );

        factory.createPair(
            address(tokenA),
            address(tokenA)
        );
    }

    function test_createPair_revertsZeroTokenA()
        public
    {
        vm.expectRevert(
            bytes(
                "ZERO_ADDRESS"
            )
        );

        factory.createPair(
            address(0),
            address(tokenB)
        );
    }

    function test_createPair_revertsZeroTokenB()
        public
    {
        vm.expectRevert(
            bytes(
                "ZERO_ADDRESS"
            )
        );

        factory.createPair(
            address(tokenA),
            address(0)
        );
    }

    function test_createPair_revertsDuplicateSameOrder()
        public
    {
        factory.createPair(
            address(tokenA),
            address(tokenB)
        );

        vm.expectRevert(
            bytes(
                "PAIR_EXISTS"
            )
        );

        factory.createPair(
            address(tokenA),
            address(tokenB)
        );
    }

    function test_createPair_revertsDuplicateReverseOrder()
        public
    {
        factory.createPair(
            address(tokenA),
            address(tokenB)
        );

        vm.expectRevert(
            bytes(
                "PAIR_EXISTS"
            )
        );

        factory.createPair(
            address(tokenB),
            address(tokenA)
        );
    }

    function test_createPair_sortsTokensCorrectly()
        public
    {
        address pairAddress =
            factory.createPair(
                address(tokenA),
                address(tokenB)
            );

        ApexV2Pair pair =
            ApexV2Pair(
                pairAddress
            );

        address expectedToken0 =
            address(tokenA) < address(tokenB)
                ? address(tokenA)
                : address(tokenB);

        address expectedToken1 =
            address(tokenA) < address(tokenB)
                ? address(tokenB)
                : address(tokenA);

        assertEq(
            pair.token0(),
            expectedToken0
        );

        assertEq(
            pair.token1(),
            expectedToken1
        );
    }

    function test_createPair_multiplePairsIncreaseLength()
        public
    {
        address pairAB =
            factory.createPair(
                address(tokenA),
                address(tokenB)
            );

        address pairAC =
            factory.createPair(
                address(tokenA),
                address(tokenC)
            );

        assertTrue(
            pairAB != pairAC
        );

        assertEq(
            factory.allPairsLength(),
            2
        );

        assertEq(
            factory.allPairs(0),
            pairAB
        );

        assertEq(
            factory.allPairs(1),
            pairAC
        );
    }

    function test_createPair_emitsCorrectEvent()
        public
    {
        address expectedToken0 =
            address(tokenA) < address(tokenB)
                ? address(tokenA)
                : address(tokenB);

        address expectedToken1 =
            address(tokenA) < address(tokenB)
                ? address(tokenB)
                : address(tokenA);

        vm.recordLogs();

        address pair =
            factory.createPair(
                address(tokenA),
                address(tokenB)
            );

        Vm.Log[] memory entries =
            vm.getRecordedLogs();

        bytes32 signature =
            keccak256(
                "PairCreated(address,address,address,uint256)"
            );

        bool found;

        for (
            uint256 i = 0;
            i < entries.length;
            i++
        ) {
            if (
                entries[i].topics.length == 3 &&
                entries[i].topics[0] == signature
            ) {
                address emittedToken0 =
                    address(
                        uint160(
                            uint256(
                                entries[i].topics[1]
                            )
                        )
                    );

                address emittedToken1 =
                    address(
                        uint160(
                            uint256(
                                entries[i].topics[2]
                            )
                        )
                    );

                (
                    address emittedPair,
                    uint256 emittedCount
                ) =
                    abi.decode(
                        entries[i].data,
                        (
                            address,
                            uint256
                        )
                    );

                assertEq(
                    emittedToken0,
                    expectedToken0
                );

                assertEq(
                    emittedToken1,
                    expectedToken1
                );

                assertEq(
                    emittedPair,
                    pair
                );

                assertEq(
                    emittedCount,
                    1
                );

                found = true;
                break;
            }
        }

        assertTrue(
            found,
            "PairCreated event not found"
        );
    }

    // ============================================================
    // SET FEE TO
    // ============================================================

    function test_setFeeTo_authorized()
        public
    {
        vm.prank(
            SETTER
        );

        factory.setFeeTo(
            FEE_TO
        );

        assertEq(
            factory.feeTo(),
            FEE_TO
        );
    }

    function test_setFeeTo_revertsUnauthorized()
        public
    {
        vm.prank(
            ATTACKER
        );

        vm.expectRevert(
            bytes(
                "FORBIDDEN"
            )
        );

        factory.setFeeTo(
            FEE_TO
        );
    }

    function test_setFeeTo_canDisableFeesWithZeroAddress()
        public
    {
        vm.startPrank(
            SETTER
        );

        factory.setFeeTo(
            FEE_TO
        );

        assertEq(
            factory.feeTo(),
            FEE_TO
        );

        factory.setFeeTo(
            address(0)
        );

        vm.stopPrank();

        assertEq(
            factory.feeTo(),
            address(0)
        );
    }

    function test_setFeeTo_emitsUpdateEvent()
    public
    {
        vm.expectEmit(
            true,
            true,
            false,
            true
        );

        emit FeeToUpdated(
            address(0),
            FEE_TO
        );

        vm.prank(
            SETTER
        );

        factory.setFeeTo(
            FEE_TO
        );

        assertEq(
            factory.feeTo(),
            FEE_TO
        );
    }
    function test_setFeeTo_sameAddressIsNoOp()
        public
    {
        vm.prank(
            SETTER
        );

        factory.setFeeTo(
            FEE_TO
        );

        assertEq(
            factory.feeTo(),
            FEE_TO
        );

        vm.recordLogs();

        vm.prank(
            SETTER
        );

        factory.setFeeTo(
            FEE_TO
        );

        Vm.Log[] memory entries =
            vm.getRecordedLogs();

        bytes32 signature =
            keccak256(
                "FeeToUpdated(address,address)"
            );

        for (
            uint256 i = 0;
            i < entries.length;
            i++
        ) {
            assertTrue(
                entries[i].topics[0] != signature,
                "unexpected FeeToUpdated event"
            );
        }

        assertEq(
            factory.feeTo(),
            FEE_TO
        );
    }

    // ============================================================
    // SET FEE TO SETTER
    // ============================================================

    function test_setFeeToSetter_authorized()
        public
    {
        vm.prank(
            SETTER
        );

        factory.setFeeToSetter(
            NEW_SETTER
        );

        assertEq(
            factory.feeToSetter(),
            NEW_SETTER
        );
    }

    function test_setFeeToSetter_revertsUnauthorized()
        public
    {
        vm.prank(
            ATTACKER
        );

        vm.expectRevert(
            bytes(
                "FORBIDDEN"
            )
        );

        factory.setFeeToSetter(
            NEW_SETTER
        );
    }

    function test_setFeeToSetter_revertsZeroSetter()
        public
    {
        vm.prank(
            SETTER
        );

        vm.expectRevert(
            bytes(
                "ZERO_SETTER"
            )
        );

        factory.setFeeToSetter(
            address(0)
        );
    }

    function test_setFeeToSetter_revertsSameSetter()
        public
    {
        vm.prank(
            SETTER
        );

        vm.expectRevert(
            bytes(
                "SAME_SETTER"
            )
        );

        factory.setFeeToSetter(
            SETTER
        );
    }

    function test_setFeeToSetter_emitsUpdateEvent()
        public
    {
        vm.expectEmit(
            true,
            true,
            false,
            true
        );

        emit FeeToSetterUpdated(
            SETTER,
            NEW_SETTER
        );

        vm.prank(
            SETTER
        );

        factory.setFeeToSetter(
            NEW_SETTER
        );
    }

    // ============================================================
    // ADMIN ROTATION
    // ============================================================

    function test_oldSetterLosesSetFeeToPermission()
        public
    {
        vm.prank(
            SETTER
        );

        factory.setFeeToSetter(
            NEW_SETTER
        );

        vm.prank(
            SETTER
        );

        vm.expectRevert(
            bytes(
                "FORBIDDEN"
            )
        );

        factory.setFeeTo(
            FEE_TO
        );
    }

    function test_oldSetterLosesSetterTransferPermission()
        public
    {
        vm.prank(
            SETTER
        );

        factory.setFeeToSetter(
            NEW_SETTER
        );

        vm.prank(
            SETTER
        );

        vm.expectRevert(
            bytes(
                "FORBIDDEN"
            )
        );

        factory.setFeeToSetter(
            ATTACKER
        );
    }

    function test_newSetterCanSetFeeTo()
        public
    {
        vm.prank(
            SETTER
        );

        factory.setFeeToSetter(
            NEW_SETTER
        );

        vm.prank(
            NEW_SETTER
        );

        factory.setFeeTo(
            FEE_TO
        );

        assertEq(
            factory.feeTo(),
            FEE_TO
        );
    }

    function test_newSetterCanTransferSetterAgain()
        public
    {
        vm.prank(
            SETTER
        );

        factory.setFeeToSetter(
            NEW_SETTER
        );

        vm.prank(
            NEW_SETTER
        );

        factory.setFeeToSetter(
            ATTACKER
        );

        assertEq(
            factory.feeToSetter(),
            ATTACKER
        );
    }

    // ============================================================
    // FUZZ
    // ============================================================

    function testFuzz_createPair_tokenOrdering(
        address tokenX,
        address tokenY
    )
        public
    {
        vm.assume(
            tokenX != address(0)
        );

        vm.assume(
            tokenY != address(0)
        );

        vm.assume(
            tokenX != tokenY
        );

        address pairAddress =
            factory.createPair(
                tokenX,
                tokenY
            );

        ApexV2Pair pair =
            ApexV2Pair(
                pairAddress
            );

        address expectedToken0 =
            tokenX < tokenY
                ? tokenX
                : tokenY;

        address expectedToken1 =
            tokenX < tokenY
                ? tokenY
                : tokenX;

        assertEq(
            pair.token0(),
            expectedToken0
        );

        assertEq(
            pair.token1(),
            expectedToken1
        );

        assertEq(
            factory.getPair(
                tokenX,
                tokenY
            ),
            pairAddress
        );

        assertEq(
            factory.getPair(
                tokenY,
                tokenX
            ),
            pairAddress
        );
    }
}