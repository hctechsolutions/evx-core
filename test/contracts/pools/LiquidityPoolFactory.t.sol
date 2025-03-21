// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {LiquidityPoolFactory} from "@nebula/contracts/pools/LiquidityPoolFactory.sol";
import {LiquidityPool} from "@nebula/contracts/pools/LiquidityPool.sol";
import {IPriceOracle} from "@nebula/interfaces/IPriceOracle.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title DummyPriceOracle
 * @dev Dummy implementation of IPriceOracle for testing purposes.
 */
contract DummyPriceOracle is IPriceOracle {
    uint256 private _price = 1e18;
    uint256 private _lastUpdated = block.timestamp;

    /**
     * @dev Returns the dummy price.
     * @return The dummy price (1e18).
     */
    function consult() external override view returns (uint256) {
        return _price;
    }

    /**
     * @dev Returns the timestamp of the last update.
     * @return The current block timestamp.
     */
    function lastUpdated() external view override returns (uint256) {
        return _lastUpdated;
    }
}

/**
 * @title DummyERC20
 * @dev Dummy ERC20 token for testing liquidity pool creation.
 */
contract DummyERC20 is ERC20 {
    /**
     * @dev Constructor that mints a large supply for testing.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e24);
    }
}

/**
 * @title LiquidityPoolFactoryTest
 * @dev Unit tests for the LiquidityPoolFactory contract.
 */
contract LiquidityPoolFactoryTest is Test {
    LiquidityPoolFactory public factory;
    DummyERC20 public token0;
    DummyERC20 public token1;
    DummyPriceOracle public oracle;

    /**
     * @dev Initial setup for tests, deploying dummy tokens, oracle and factory.
     */
    function setUp() public {
        // Deploy the factory (permissionless creation)
        factory = new LiquidityPoolFactory();
        // Deploy dummy tokens and oracle for testing
        token0 = new DummyERC20("Token0", "TK0");
        token1 = new DummyERC20("Token1", "TK1");
        oracle = new DummyPriceOracle();
    }

    /**
     * @dev Tests creating a new LiquidityPool through the factory.
     */
    function testCreateLiquidityPool() public {
        // Create a new LiquidityPool through the factory
        LiquidityPool pool = factory.createLiquidityPool(
            address(token0),
            address(token1),
            address(oracle)
        );

        // Verify if the parameters of the pool are correctly set
        assertEq(address(pool.token0()), address(token0), "Token0 address mismatch");
        assertEq(address(pool.token1()), address(token1), "Token1 address mismatch");
        assertEq(address(pool.oracle()), address(oracle), "Oracle address mismatch");

        // Verify that the pool count is incremented
        uint256 count = factory.getLiquidityPoolCount();
        assertEq(count, 1, "Pool count should be 1");
    }

    /**
     * @dev Tests that creation reverts if one of the token addresses is invalid or tokens are the same.
     */
    function testRevertOnInvalidTokenAddresses() public {
        vm.expectRevert("Invalid token addresses");
        factory.createLiquidityPool(address(0), address(token1), address(oracle));
        vm.expectRevert("Invalid token addresses");
        factory.createLiquidityPool(address(token0), address(0), address(oracle));

        vm.expectRevert("Token addresses must be different");
        factory.createLiquidityPool(
            address(token0),
            address(token0),
            address(oracle)
        );
    }

    /**
     * @dev Tests that creation reverts if the oracle address is invalid.
     */
    function testRevertOnInvalidOracle() public {
        vm.expectRevert("Invalid oracle address");
        factory.createLiquidityPool(address(token0), address(token1), address(0));
    }

    /**
     * @dev Tests that the pool count increases correctly after creating multiple pools.
     */
    function testMultiplePoolsCount() public {
        factory.createLiquidityPool(address(token0), address(token1), address(oracle));
        factory.createLiquidityPool(address(token0), address(token1), address(oracle));
        uint256 count = factory.getLiquidityPoolCount();
        assertEq(count, 2, "Pool count should be 2");
    }
}
