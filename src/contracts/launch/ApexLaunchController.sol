// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


interface IERC20 {

    function approve(
        address spender,
        uint amount
    )
    external
    returns(bool);


    function balanceOf(
        address account
    )
    external
    view
    returns(uint);

}





interface IRouter {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
    external
    payable
    returns(
        uint amountA,
        uint amountB,
        uint liquidity
    );

}





interface IFactory {

    function getPair(
        address tokenA,
        address tokenB
    )
    external
    view
    returns(address);

}





interface IApexVesting {

    function createVesting(
        address user,
        uint256 amount,
        uint256 startTime,
        uint256 cliff,
        uint256 duration
    )
    external;

}








contract ApexLaunchController {


    address public owner;


    address public immutable token;


    address public immutable router;


    address public immutable factory;


    address public immutable vesting;


    address public lpToken;


    bool public launched;





    event Launched(
        address pair,
        uint amountToken,
        uint amountETH,
        uint liquidity
    );



    event VestingCreated(
        address indexed user,
        uint amount,
        uint cliff,
        uint duration
    );



    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );







    modifier onlyOwner(){

        require(
            msg.sender == owner,
            "not owner"
        );

        _;
    }









    constructor(
        address _token,
        address _router,
        address _factory,
        address _vesting
    )
    {

        require(
            _token != address(0),
            "zero token"
        );


        require(
            _router != address(0),
            "zero router"
        );


        require(
            _factory != address(0),
            "zero factory"
        );


        require(
            _vesting != address(0),
            "zero vesting"
        );


        owner =
            msg.sender;


        token =
            _token;


        router =
            _router;


        factory =
            _factory;


        vesting =
            _vesting;

    }









    function launch(
        address weth,
        uint tokenAmount,
        uint ethAmount
    )
    external
    payable
    onlyOwner
    {


        require(
            !launched,
            "already launched"
        );


        require(
            weth != address(0),
            "zero weth"
        );


        require(
            tokenAmount > 0,
            "zero token amount"
        );


        require(
            ethAmount > 0,
            "zero eth amount"
        );


        require(
            msg.value == ethAmount,
            "wrong ETH"
        );


        require(
            IERC20(token)
            .balanceOf(
                address(this)
            )
            >= tokenAmount,
            "insufficient token balance"
        );



        require(
            IERC20(token)
            .approve(
                router,
                tokenAmount
            ),
            "approve failed"
        );







        (
            ,
            ,
            uint liquidity
        )
        =
        IRouter(router)
        .addLiquidity{value: ethAmount}(
            token,
            weth,
            tokenAmount,
            ethAmount,
            0,
            0,
            address(this),
            block.timestamp + 1 hours
        );





        require(
            liquidity > 0,
            "no liquidity"
        );





        lpToken =
            IFactory(factory)
            .getPair(
                token,
                weth
            );




        require(
            lpToken != address(0),
            "pair not created"
        );



        launched =
            true;



        emit Launched(
            lpToken,
            tokenAmount,
            ethAmount,
            liquidity
        );

    }









    function createVesting(
        address user,
        uint256 amount,
        uint256 cliff,
        uint256 duration
    )
    external
    onlyOwner
    {


        require(
            user != address(0),
            "zero user"
        );


        require(
            amount > 0,
            "zero amount"
        );



        IApexVesting(vesting)
        .createVesting(
            user,
            amount,
            block.timestamp,
            cliff,
            duration
        );



        emit VestingCreated(
            user,
            amount,
            cliff,
            duration
        );

    }









    function transferOwnership(
        address newOwner
    )
    external
    onlyOwner
    {


        require(
            newOwner != address(0),
            "zero owner"
        );



        emit OwnershipTransferred(
            owner,
            newOwner
        );



        owner =
            newOwner;

    }


}