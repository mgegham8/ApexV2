// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../src/contracts/ApexV2Router.sol";
import "../src/contracts/ApexV2Pair.sol";
import "../src/contracts/test/MockERC20.sol";
import "../src/contracts/test/MockFactory.sol";

contract MockWETH {
    string public name = "Wrapped ETH";
    string public symbol = "WETH";

    mapping(address => uint256) public balanceOf;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "NO_BALANCE");

        balanceOf[msg.sender] -= amount;

        payable(msg.sender).transfer(amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        return true;
    }

    receive() external payable {}
}

contract ApexV2RouterETHSecurityTest is Test {
    ApexV2Router router;

    MockFactory factory;

    MockERC20 token;

    MockWETH weth;

    function setUp() public {
        factory = new MockFactory();

        token = new MockERC20("Token", "TKN");

        weth = new MockWETH();

        router = new ApexV2Router(address(factory), address(weth));
    }

    function testReceiveOnlyWETH() public {
        vm.expectRevert();

        payable(address(router)).transfer(1 ether);
    }

    function testSwapETHWrongPathFails() public {
        address[] memory path = new address[](2);

        path[0] = address(token);
        path[1] = address(weth);

        vm.expectRevert();

        router.swapExactETHForTokens{value: 1 ether}(0, path, address(this), block.timestamp + 1 hours);
    }

    function testAddLiquidityETHRejectsWrongToken() public {
        vm.expectRevert();

        router.addLiquidityETH{value: 1 ether}(address(weth), 1 ether, 0, 0, address(this), block.timestamp + 1 hours);
    }

    function testDeadlineProtectionETH() public {
        vm.expectRevert();

        router.addLiquidityETH{value: 1 ether}(address(token), 1 ether, 0, 0, address(this), block.timestamp - 1);
    }
}
