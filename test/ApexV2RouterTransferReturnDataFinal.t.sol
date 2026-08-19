// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";

import {
    ApexV2Router
} from "../src/contracts/ApexV2Router.sol";

import {
    ApexV2Factory
} from "../src/contracts/ApexV2Factory.sol";

import {
    MockERC20
} from "../src/contracts/test/MockERC20.sol";

import {
    WETH9
} from "../src/contracts/test/WETH9.sol";


contract ReturnTrueToken {
    string public name = "TRUE";
    string public symbol = "TRUE";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        allowance[msg.sender][spender] =
            amount;

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        require(
            balanceOf[msg.sender] >= amount,
            "BALANCE"
        );

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        require(
            balanceOf[from] >= amount,
            "BALANCE"
        );

        uint256 allowed =
            allowance[from][msg.sender];

        require(
            allowed >= amount,
            "ALLOWANCE"
        );

        if (
            allowed !=
            type(uint256).max
        ) {
            allowance[from][msg.sender] =
                allowed - amount;
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        return true;
    }
}


contract ReturnFalseToken {
    string public name = "FALSE";
    string public symbol = "FALSE";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        allowance[msg.sender][spender] =
            amount;

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        require(
            balanceOf[msg.sender] >= amount,
            "BALANCE"
        );

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        uint256 allowed =
            allowance[from][msg.sender];

        require(
            allowed >= amount,
            "ALLOWANCE"
        );

        require(
            balanceOf[from] >= amount,
            "BALANCE"
        );

        allowance[from][msg.sender] =
            allowed - amount;

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        return false;
    }
}


contract NoReturnToken {
    string public name = "NORETURN";
    string public symbol = "NORETURN";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(
        address spender,
        uint256 amount
    )
        external
    {
        allowance[msg.sender][spender] =
            amount;
    }

    function transfer(
        address to,
        uint256 amount
    )
        external
    {
        require(
            balanceOf[msg.sender] >= amount,
            "BALANCE"
        );

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
    {
        uint256 allowed =
            allowance[from][msg.sender];

        require(
            allowed >= amount,
            "ALLOWANCE"
        );

        require(
            balanceOf[from] >= amount,
            "BALANCE"
        );

        allowance[from][msg.sender] =
            allowed - amount;

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}


contract RevertingToken {
    string public name = "REVERT";
    string public symbol = "REVERT";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        allowance[msg.sender][spender] =
            amount;

        return true;
    }

    function transfer(
        address,
        uint256
    )
        external
        pure
        returns (bool)
    {
        revert(
            "TRANSFER_REVERT"
        );
    }

    function transferFrom(
        address,
        address,
        uint256
    )
        external
        pure
        returns (bool)
    {
        revert(
            "TRANSFER_FROM_REVERT"
        );
    }
}


contract MalformedReturnToken {
    string public name = "MALFORMED";
    string public symbol = "MAL";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256)
        public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    function mint(
        address to,
        uint256 amount
    )
        external
    {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        allowance[msg.sender][spender] =
            amount;

        return true;
    }

    fallback()
        external
    {
        assembly {
            mstore(
                0x00,
                0x01
            )

            return(
                0x1f,
                0x01
            )
        }
    }
}


contract ApexV2RouterTransferReturnDataFinalTest is Test {
    ApexV2Factory internal factory;
    ApexV2Router internal router;
    WETH9 internal weth;

    MockERC20 internal normalToken;

    address internal user;

    uint256 internal constant AMOUNT =
        100 ether;


    function setUp()
        public
    {
        user =
            makeAddr(
                "user"
            );

        weth =
            new WETH9();

        factory =
            new ApexV2Factory(
                address(this)
            );

        router =
            new ApexV2Router(
                address(factory),
                address(weth)
            );

        normalToken =
            new MockERC20(
                "NORMAL",
                "NORMAL"
            );

        normalToken.mint(
            user,
            10_000 ether
        );

        vm.prank(user);

        normalToken.approve(
            address(router),
            type(uint256).max
        );
    }


    // =============================================================
    // TRANSFER FROM - TRUE RETURN
    // =============================================================

    function test_transferFrom_trueReturnAccepted()
        public
    {
        ReturnTrueToken token =
            new ReturnTrueToken();

        token.mint(
            user,
            10_000 ether
        );

        vm.startPrank(
            user
        );

        token.approve(
            address(router),
            type(uint256).max
        );

        (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        ) =
            router.addLiquidity(
                address(token),
                address(normalToken),
                AMOUNT,
                AMOUNT,
                0,
                0,
                user,
                block.timestamp +
                    1 days
            );

        vm.stopPrank();

        assertEq(
            amountA,
            AMOUNT
        );

        assertEq(
            amountB,
            AMOUNT
        );

        assertGt(
            liquidity,
            0
        );
    }


    // =============================================================
    // TRANSFER FROM - NO RETURN
    // =============================================================

    function test_transferFrom_noReturnAccepted()
        public
    {
        NoReturnToken token =
            new NoReturnToken();

        token.mint(
            user,
            10_000 ether
        );

        vm.startPrank(
            user
        );

        token.approve(
            address(router),
            type(uint256).max
        );

        (
            ,
            ,
            uint256 liquidity
        ) =
            router.addLiquidity(
                address(token),
                address(normalToken),
                AMOUNT,
                AMOUNT,
                0,
                0,
                user,
                block.timestamp +
                    1 days
            );

        vm.stopPrank();

        assertGt(
            liquidity,
            0
        );
    }


    // =============================================================
    // TRANSFER FROM - FALSE RETURN
    // =============================================================

    function test_transferFrom_falseReturnRejected()
        public
    {
        ReturnFalseToken token =
            new ReturnFalseToken();

        token.mint(
            user,
            10_000 ether
        );

        vm.startPrank(
            user
        );

        token.approve(
            address(router),
            type(uint256).max
        );

        vm.expectRevert(
            bytes(
                "ApexV2Router: TRANSFER_FROM_FALSE"
            )
        );

        router.addLiquidity(
            address(token),
            address(normalToken),
            AMOUNT,
            AMOUNT,
            0,
            0,
            user,
            block.timestamp +
                1 days
        );

        vm.stopPrank();
    }


    // =============================================================
    // TRANSFER FROM - UNDERLYING REVERT
    // =============================================================

    function test_transferFrom_revertingTokenRejected()
        public
    {
        RevertingToken token =
            new RevertingToken();

        token.mint(
            user,
            10_000 ether
        );

        vm.startPrank(
            user
        );

        token.approve(
            address(router),
            type(uint256).max
        );

        vm.expectRevert(
            bytes(
                "ApexV2Router: TRANSFER_FROM_FAILED"
            )
        );

        router.addLiquidity(
            address(token),
            address(normalToken),
            AMOUNT,
            AMOUNT,
            0,
            0,
            user,
            block.timestamp +
                1 days
        );

        vm.stopPrank();
    }


    // =============================================================
    // TRANSFER FROM - MALFORMED RETURN DATA
    // =============================================================

    function test_transferFrom_malformedReturnRejected()
        public
    {
        MalformedReturnToken token =
            new MalformedReturnToken();

        token.mint(
            user,
            10_000 ether
        );

        vm.prank(user);

        token.approve(
            address(router),
            type(uint256).max
        );

        /*
         * approve() itself has a normal ABI implementation.
         *
         * transferFrom() does not exist, therefore fallback()
         * executes and returns exactly one byte.
         */

        vm.prank(
            user
        );

        vm.expectRevert(
            bytes(
                "ApexV2Router: TRANSFER_FROM_FALSE"
            )
        );

        router.addLiquidity(
            address(token),
            address(normalToken),
            AMOUNT,
            AMOUNT,
            0,
            0,
            user,
            block.timestamp +
                1 days
        );
    }


    // =============================================================
    // TRANSFER - TRUE RETURN
    // =============================================================

    function test_transfer_trueReturnAcceptedViaAddLiquidityETH()
        public
    {
        /*
         * Router's _safeTransfer() is used on WETH during
         * addLiquidityETH(), so this exercises the standard
         * 32-byte bool(true) path.
         */

        vm.deal(
            user,
            100 ether
        );

        vm.startPrank(
            user
        );

        normalToken.approve(
            address(router),
            type(uint256).max
        );

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) =
            router.addLiquidityETH{
                value: 10 ether
            }(
                address(normalToken),
                1_000 ether,
                0,
                0,
                user,
                block.timestamp +
                    1 days
            );

        vm.stopPrank();

        assertEq(
            amountToken,
            1_000 ether
        );

        assertEq(
            amountETH,
            10 ether
        );

        assertGt(
            liquidity,
            0
        );
    }


    // =============================================================
    // TRANSFER - ETH FAILURE PATH
    // =============================================================

    function test_ethTransfer_failureStillRejected()
        public
    {
        RejectETHReceiver receiver =
            new RejectETHReceiver();

        vm.deal(
            user,
            100 ether
        );

        vm.startPrank(
            user
        );

        normalToken.approve(
            address(router),
            type(uint256).max
        );

        router.addLiquidityETH{
            value: 10 ether
        }(
            address(normalToken),
            1_000 ether,
            0,
            0,
            user,
            block.timestamp +
                1 days
        );

        address pair =
            factory.getPair(
                address(normalToken),
                address(weth)
            );

        uint256 lp =
            IERC20Like(pair)
                .balanceOf(user);

        IERC20Like(pair)
            .approve(
                address(router),
                lp
            );

        vm.expectRevert(
            bytes(
                "ApexV2Router: ETH_TRANSFER_FAILED"
            )
        );

        router.removeLiquidityETH(
            address(normalToken),
            lp,
            0,
            0,
            address(receiver),
            block.timestamp +
                1 days
        );

        vm.stopPrank();
    }
}


interface IERC20Like {
    function balanceOf(
        address account
    )
        external
        view
        returns (uint256);

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);
}


contract RejectETHReceiver {
    receive()
        external
        payable
    {
        revert(
            "NO_ETH"
        );
    }
}