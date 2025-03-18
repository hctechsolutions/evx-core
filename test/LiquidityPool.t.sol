// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@nebula/contracts/LiquidityPool.sol";
import "@nebula/interfaces/IPriceOracle.sol";
import "forge-std/console.sol";

/**
 * @title LiquidityPoolTest
 * @dev Unit tests for the LiquidityPool contract
 */
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1e24); // 1M tokens for testing
    }
}

contract MockOracle is IPriceOracle {
    uint256 private _price;
    uint256 private _lastUpdated;

    function setPrice(uint256 price) external {
        _price = price;
        _lastUpdated = block.timestamp;
    }

    function consult() external view override returns (uint256) {
        return _price;
    }

    function lastUpdated() external view override returns (uint256) {
        return _lastUpdated;
    }
}

contract LiquidityPoolTest is Test {
    LiquidityPool public pool;
    MockERC20 public token0;
    MockERC20 public token1;
    MockOracle public oracle;
    address public dao = address(0xDA0);
    address public user = address(0x123);

    /**
     * @dev Initial setup for contracts and approvals
     */
    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");
        oracle = new MockOracle();
        pool = new LiquidityPool(address(token0), address(token1), IPriceOracle(address(oracle)), dao);

        token0.transfer(user, 1e22);
        token1.transfer(user, 1e22);
        vm.startPrank(user);
        token0.approve(address(pool), type(uint256).max);
        token1.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    /**
     * @dev Tests adding liquidity
     */
    function testAddLiquidity() public {
        vm.startPrank(user);
        pool.addLiquidity(1e18, 1e18);
        vm.stopPrank();

        assertEq(pool.reserve0(), 1e18);
        assertEq(pool.reserve1(), 1e18);
    }

    /**
     * @dev Tests the swap functionality
     */
    function testSwap() public {
        oracle.setPrice(2e18); // 1 token0 = 2 token1

        vm.startPrank(user);
        pool.addLiquidity(1e18, 2e18);
        
        uint256 beforeBalanceToken1 = token1.balanceOf(user);
        uint256 amountOut = pool.swap(address(token0), 1e18);
        uint256 afterBalanceToken1 = token1.balanceOf(user);

        vm.stopPrank();

        assertEq(amountOut, 2e18);
        assertEq(afterBalanceToken1 - beforeBalanceToken1, 2e18);
    }

    /**
     * @dev Tests if only the DAO can change the DAO address
     */
    function testOnlyDAOSetDAO() public {
        address newDAO = address(0x1); // New test DAO address
        address anyAddr = address(0x5); // Any address other than DAO

        vm.startPrank(anyAddr); // Assume that any non-DAO address tries to set the DAO
        
        // Check if the call reverts correctly
        vm.expectRevert("Unauthorized: DAO only");
        pool.setDAO(newDAO);
        
        vm.stopPrank();
    }
    
    /**
     * @dev Tests updating the DAO address
     */
    function testSetDAO() public {
        address newDAO = address(0x1); // New test DAO address

        vm.startPrank(dao); // Assume that only the DAO can call setDAO
        pool.setDAO(newDAO);
        vm.stopPrank();

        // Check if the DAO was updated correctly
        assertEq(pool.dao(), newDAO);
    }
}