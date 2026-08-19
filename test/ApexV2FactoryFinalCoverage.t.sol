// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {
    ApexV2Factory
} from "../src/contracts/ApexV2Factory.sol";

import {
    ApexV2Pair
} from "../src/contracts/ApexV2Pair.sol";


contract ApexV2FactoryFinalCoverageTest is Test {
    ApexV2Factory internal factory;

    address internal setter;
    address internal newSetter;
    address internal attacker;

    address internal tokenA;
    address internal tokenB;
    address internal tokenC;


    function setUp()
        public
    {
        setter =
            makeAddr("setter");

        newSetter =
            makeAddr("newSetter");

        attacker =
            makeAddr("attacker");

        tokenA =
            makeAddr("tokenA");

        tokenB =
            makeAddr("tokenB");

        tokenC =
            makeAddr("tokenC");

        factory =
            new ApexV2Factory(
                setter
            );
    }


    // =============================================================
    // CONSTRUCTOR
    // =============================================================

    function test_constructor_setsFeeToSetter()
        public
        view
    {
        assertEq(
            factory.feeToSetter(),
            setter
        );
    }


    function test_constructor_feeToInitiallyZero()
        public
        view
    {
        assertEq(
            factory.feeTo(),
            address(0)
        );
    }


    function test_constructor_allPairsInitiallyEmpty()
        public
        view
    {
        assertEq(
            factory.allPairsLength(),
            0
        );
    }


    function test_constructor_revertsZeroSetter()
        public
    {
        vm.expectRevert(
            bytes("ZERO_SETTER")
        );

        new ApexV2Factory(
            address(0)
        );
    }


    // =============================================================
    // CREATE PAIR
    // =============================================================

    function test_createPair_success()
        public
    {
        address pair =
            factory.createPair(
                tokenA,
                tokenB
            );

        assertTrue(
            pair != address(0)
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


    function test_createPair_sortsTokensCorrectly()
        public
    {
        address pair =
            factory.createPair(
                tokenA,
                tokenB
            );

        address expectedToken0 =
            tokenA < tokenB
                ? tokenA
                : tokenB;

        address expectedToken1 =
            tokenA < tokenB
                ? tokenB
                : tokenA;

        assertEq(
            ApexV2Pair(pair).token0(),
            expectedToken0
        );

        assertEq(
            ApexV2Pair(pair).token1(),
            expectedToken1
        );
    }


    function test_createPair_reverseInputOrderSortsCorrectly()
        public
    {
        address pair =
            factory.createPair(
                tokenB,
                tokenA
            );

        address expectedToken0 =
            tokenA < tokenB
                ? tokenA
                : tokenB;

        address expectedToken1 =
            tokenA < tokenB
                ? tokenB
                : tokenA;

        assertEq(
            ApexV2Pair(pair).token0(),
            expectedToken0
        );

        assertEq(
            ApexV2Pair(pair).token1(),
            expectedToken1
        );
    }


    function test_createPair_registersBothDirections()
        public
    {
        address pair =
            factory.createPair(
                tokenA,
                tokenB
            );

        assertEq(
            factory.getPair(
                tokenA,
                tokenB
            ),
            pair
        );

        assertEq(
            factory.getPair(
                tokenB,
                tokenA
            ),
            pair
        );
    }


    function test_createPair_pairFactoryIsFactory()
        public
    {
        address pair =
            factory.createPair(
                tokenA,
                tokenB
            );

        assertEq(
            ApexV2Pair(pair).factory(),
            address(factory)
        );
    }


    function test_createPair_emitsEvent()
        public
    {
        address expectedToken0 =
            tokenA < tokenB
                ? tokenA
                : tokenB;

        address expectedToken1 =
            tokenA < tokenB
                ? tokenB
                : tokenA;

        /*
         * Pair address cannot be known conveniently before CREATE,
         * so only indexed token fields and pairCount are useful here.
         *
         * Pair address itself is not indexed.
         */
        vm.recordLogs();

        address pair =
            factory.createPair(
                tokenA,
                tokenB
            );

        Vm.Log[] memory logs =
            vm.getRecordedLogs();

        bytes32 eventSignature =
            keccak256(
                "PairCreated(address,address,address,uint256)"
            );

        bool found;

        for (
            uint256 i = 0;
            i < logs.length;
            ++i
        ) {
            if (
                logs[i].emitter ==
                    address(factory) &&
                logs[i].topics.length ==
                    3 &&
                logs[i].topics[0] ==
                    eventSignature
            ) {
                assertEq(
                    address(
                        uint160(
                            uint256(
                                logs[i].topics[1]
                            )
                        )
                    ),
                    expectedToken0
                );

                assertEq(
                    address(
                        uint160(
                            uint256(
                                logs[i].topics[2]
                            )
                        )
                    ),
                    expectedToken1
                );

                (
                    address emittedPair,
                    uint256 pairCount
                ) =
                    abi.decode(
                        logs[i].data,
                        (
                            address,
                            uint256
                        )
                    );

                assertEq(
                    emittedPair,
                    pair
                );

                assertEq(
                    pairCount,
                    1
                );

                found =
                    true;

                break;
            }
        }

        assertTrue(
            found
        );
    }


    function test_createPair_revertsIdenticalAddresses()
        public
    {
        vm.expectRevert(
            bytes(
                "IDENTICAL_ADDRESSES"
            )
        );

        factory.createPair(
            tokenA,
            tokenA
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
            tokenB
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
            tokenA,
            address(0)
        );
    }


    function test_createPair_revertsDuplicateSameOrder()
        public
    {
        factory.createPair(
            tokenA,
            tokenB
        );

        vm.expectRevert(
            bytes(
                "PAIR_EXISTS"
            )
        );

        factory.createPair(
            tokenA,
            tokenB
        );
    }


    function test_createPair_revertsDuplicateReverseOrder()
        public
    {
        address pair =
            factory.createPair(
                tokenA,
                tokenB
            );

        vm.expectRevert(
            bytes(
                "PAIR_EXISTS"
            )
        );

        factory.createPair(
            tokenB,
            tokenA
        );

        assertEq(
            factory.getPair(
                tokenA,
                tokenB
            ),
            pair
        );

        assertEq(
            factory.allPairsLength(),
            1
        );
    }


    function test_createPair_multiplePairsTrackedCorrectly()
        public
    {
        address pairAB =
            factory.createPair(
                tokenA,
                tokenB
            );

        address pairAC =
            factory.createPair(
                tokenA,
                tokenC
            );

        address pairBC =
            factory.createPair(
                tokenB,
                tokenC
            );

        assertEq(
            factory.allPairsLength(),
            3
        );

        assertEq(
            factory.allPairs(0),
            pairAB
        );

        assertEq(
            factory.allPairs(1),
            pairAC
        );

        assertEq(
            factory.allPairs(2),
            pairBC
        );

        assertTrue(
            pairAB != pairAC
        );

        assertTrue(
            pairAB != pairBC
        );

        assertTrue(
            pairAC != pairBC
        );
    }


    function test_createPair_doesNotModifyFeeConfiguration()
        public
    {
        vm.prank(setter);

        factory.setFeeTo(
            makeAddr("feeReceiver")
        );

        address feeToBefore =
            factory.feeTo();

        address setterBefore =
            factory.feeToSetter();

        factory.createPair(
            tokenA,
            tokenB
        );

        assertEq(
            factory.feeTo(),
            feeToBefore
        );

        assertEq(
            factory.feeToSetter(),
            setterBefore
        );
    }


    // =============================================================
    // SET FEE TO
    // =============================================================

    function test_setFeeTo_success()
        public
    {
        address feeReceiver =
            makeAddr(
                "feeReceiver"
            );

        vm.prank(setter);

        factory.setFeeTo(
            feeReceiver
        );

        assertEq(
            factory.feeTo(),
            feeReceiver
        );
    }


    function test_setFeeTo_canDisableWithZeroAddress()
        public
    {
        address feeReceiver =
            makeAddr(
                "feeReceiver"
            );

        vm.startPrank(
            setter
        );

        factory.setFeeTo(
            feeReceiver
        );

        assertEq(
            factory.feeTo(),
            feeReceiver
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


    function test_setFeeTo_sameValueIsNoOp()
        public
    {
        address feeReceiver =
            makeAddr(
                "feeReceiver"
            );

        vm.prank(setter);

        factory.setFeeTo(
            feeReceiver
        );

        vm.recordLogs();

        vm.prank(setter);

        factory.setFeeTo(
            feeReceiver
        );

        Vm.Log[] memory logs =
            vm.getRecordedLogs();

        assertEq(
            factory.feeTo(),
            feeReceiver
        );

        /*
         * No-op path returns before emitting FeeToUpdated.
         */
        assertEq(
            logs.length,
            0
        );
    }


    function test_setFeeTo_zeroToZeroIsNoOp()
        public
    {
        assertEq(
            factory.feeTo(),
            address(0)
        );

        vm.recordLogs();

        vm.prank(setter);

        factory.setFeeTo(
            address(0)
        );

        Vm.Log[] memory logs =
            vm.getRecordedLogs();

        assertEq(
            factory.feeTo(),
            address(0)
        );

        assertEq(
            logs.length,
            0
        );
    }


    function test_setFeeTo_emitsEvent()
        public
    {
        address feeReceiver =
            makeAddr(
                "feeReceiver"
            );

        vm.expectEmit(
            true,
            true,
            false,
            true,
            address(factory)
        );

        emit ApexV2Factory
            .FeeToUpdated(
                address(0),
                feeReceiver
            );

        vm.prank(setter);

        factory.setFeeTo(
            feeReceiver
        );
    }


    function test_setFeeTo_emitsPreviousAndNewValues()
        public
    {
        address feeReceiver1 =
            makeAddr(
                "feeReceiver1"
            );

        address feeReceiver2 =
            makeAddr(
                "feeReceiver2"
            );

        vm.prank(setter);

        factory.setFeeTo(
            feeReceiver1
        );

        vm.expectEmit(
            true,
            true,
            false,
            true,
            address(factory)
        );

        emit ApexV2Factory
            .FeeToUpdated(
                feeReceiver1,
                feeReceiver2
            );

        vm.prank(setter);

        factory.setFeeTo(
            feeReceiver2
        );

        assertEq(
            factory.feeTo(),
            feeReceiver2
        );
    }


    function test_setFeeTo_revertsNonSetter()
        public
    {
        vm.prank(attacker);

        vm.expectRevert(
            bytes(
                "FORBIDDEN"
            )
        );

        factory.setFeeTo(
            attacker
        );

        assertEq(
            factory.feeTo(),
            address(0)
        );
    }


    // =============================================================
    // SET FEE TO SETTER
    // =============================================================

    function test_setFeeToSetter_success()
        public
    {
        vm.prank(setter);

        factory.setFeeToSetter(
            newSetter
        );

        assertEq(
            factory.feeToSetter(),
            newSetter
        );
    }


    function test_setFeeToSetter_emitsEvent()
        public
    {
        vm.expectEmit(
            true,
            true,
            false,
            true,
            address(factory)
        );

        emit ApexV2Factory
            .FeeToSetterUpdated(
                setter,
                newSetter
            );

        vm.prank(setter);

        factory.setFeeToSetter(
            newSetter
        );
    }


    function test_setFeeToSetter_revertsNonSetter()
        public
    {
        vm.prank(attacker);

        vm.expectRevert(
            bytes(
                "FORBIDDEN"
            )
        );

        factory.setFeeToSetter(
            newSetter
        );

        assertEq(
            factory.feeToSetter(),
            setter
        );
    }


    function test_setFeeToSetter_revertsZeroSetter()
        public
    {
        vm.prank(setter);

        vm.expectRevert(
            bytes(
                "ZERO_SETTER"
            )
        );

        factory.setFeeToSetter(
            address(0)
        );

        assertEq(
            factory.feeToSetter(),
            setter
        );
    }


    function test_setFeeToSetter_revertsSameSetter()
        public
    {
        vm.prank(setter);

        vm.expectRevert(
            bytes(
                "SAME_SETTER"
            )
        );

        factory.setFeeToSetter(
            setter
        );

        assertEq(
            factory.feeToSetter(),
            setter
        );
    }


    function test_setFeeToSetter_oldSetterLosesAuthority()
        public
    {
        vm.prank(setter);

        factory.setFeeToSetter(
            newSetter
        );

        vm.prank(setter);

        vm.expectRevert(
            bytes(
                "FORBIDDEN"
            )
        );

        factory.setFeeTo(
            makeAddr("feeReceiver")
        );
    }


    function test_setFeeToSetter_newSetterCanSetFeeTo()
        public
    {
        address feeReceiver =
            makeAddr(
                "feeReceiver"
            );

        vm.prank(setter);

        factory.setFeeToSetter(
            newSetter
        );

        vm.prank(newSetter);

        factory.setFeeTo(
            feeReceiver
        );

        assertEq(
            factory.feeTo(),
            feeReceiver
        );
    }


    function test_setFeeToSetter_newSetterCanTransferAuthorityAgain()
        public
    {
        address thirdSetter =
            makeAddr(
                "thirdSetter"
            );

        vm.prank(setter);

        factory.setFeeToSetter(
            newSetter
        );

        vm.prank(newSetter);

        factory.setFeeToSetter(
            thirdSetter
        );

        assertEq(
            factory.feeToSetter(),
            thirdSetter
        );
    }


    function test_setFeeToSetter_doesNotModifyFeeTo()
        public
    {
        address feeReceiver =
            makeAddr(
                "feeReceiver"
            );

        vm.prank(setter);

        factory.setFeeTo(
            feeReceiver
        );

        vm.prank(setter);

        factory.setFeeToSetter(
            newSetter
        );

        assertEq(
            factory.feeTo(),
            feeReceiver
        );

        assertEq(
            factory.feeToSetter(),
            newSetter
        );
    }


    // =============================================================
    // FUZZ
    // =============================================================

    function testFuzz_createPair_bidirectionalMapping(
        address fuzzTokenA,
        address fuzzTokenB
    )
        public
    {
        vm.assume(
            fuzzTokenA !=
                address(0)
        );

        vm.assume(
            fuzzTokenB !=
                address(0)
        );

        vm.assume(
            fuzzTokenA !=
                fuzzTokenB
        );

        address pair =
            factory.createPair(
                fuzzTokenA,
                fuzzTokenB
            );

        assertTrue(
            pair != address(0)
        );

        assertEq(
            factory.getPair(
                fuzzTokenA,
                fuzzTokenB
            ),
            pair
        );

        assertEq(
            factory.getPair(
                fuzzTokenB,
                fuzzTokenA
            ),
            pair
        );
    }


    function testFuzz_createPair_tokenOrdering(
        address fuzzTokenA,
        address fuzzTokenB
    )
        public
    {
        vm.assume(
            fuzzTokenA !=
                address(0)
        );

        vm.assume(
            fuzzTokenB !=
                address(0)
        );

        vm.assume(
            fuzzTokenA !=
                fuzzTokenB
        );

        address pair =
            factory.createPair(
                fuzzTokenA,
                fuzzTokenB
            );

        address expectedToken0 =
            fuzzTokenA <
            fuzzTokenB
                ? fuzzTokenA
                : fuzzTokenB;

        address expectedToken1 =
            fuzzTokenA <
            fuzzTokenB
                ? fuzzTokenB
                : fuzzTokenA;

        assertEq(
            ApexV2Pair(pair).token0(),
            expectedToken0
        );

        assertEq(
            ApexV2Pair(pair).token1(),
            expectedToken1
        );
    }


    function testFuzz_setFeeTo(
        address feeReceiver
    )
        public
    {
        vm.prank(setter);

        factory.setFeeTo(
            feeReceiver
        );

        assertEq(
            factory.feeTo(),
            feeReceiver
        );
    }


    function testFuzz_setFeeToSetter(
        address fuzzSetter
    )
        public
    {
        vm.assume(
            fuzzSetter !=
                address(0)
        );

        vm.assume(
            fuzzSetter !=
                setter
        );

        vm.prank(setter);

        factory.setFeeToSetter(
            fuzzSetter
        );

        assertEq(
            factory.feeToSetter(),
            fuzzSetter
        );
    }
}