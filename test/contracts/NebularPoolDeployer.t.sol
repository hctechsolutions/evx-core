// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebular/contracts/NebularPoolDeployer.sol";
import "@nebular/contracts/NebularPool.sol";

/// @notice Harness to expose internal deploy function for testing
contract PoolDeployerHarness is NebularPoolDeployer {
    /**
     * @notice Public wrapper to call internal deploy
     */
    function deployPublic(
        address factory_,
        address token0_,
        address token1_,
        uint24 fee_,
        int24 tickSpacing_
    ) external returns (address) {
        return deploy(factory_, token0_, token1_, fee_, tickSpacing_);
    }
}

/// @title Tests for NebularPoolDeployer
/// @dev Uses deterministic CREATE2 deployment to verify pool parameters and behavior
contract NebularPoolDeployerTest is Test {
    PoolDeployerHarness deployer;
    address factory;
    address token0;
    address token1;
    uint24 fee;
    int24 tickSpacing;

    /**
     * @notice Set up deployer instance and sample parameters
     */
    function setUp() public {
        deployer = new PoolDeployerHarness();
        factory = address(this);
        token0 = address(0x100);
        token1 = address(0x200);
        fee = 500;
        tickSpacing = 10;
    }

    /**
     * @notice Deployment sets correct immutable parameters on NebularPool
     */
    function testDeploySetsCorrectParameters() public {
        address poolAddr = deployer.deployPublic(factory, token0, token1, fee, tickSpacing);
        NebularPool pool = NebularPool(payable(poolAddr));
        assertEq(pool.factory(), factory, "Factory address mismatch");
        assertEq(pool.token0(), token0, "Token0 mismatch");
        assertEq(pool.token1(), token1, "Token1 mismatch");
        assertEq(pool.fee(), fee, "Fee mismatch");
        assertEq(pool.tickSpacing(), tickSpacing, "Tick spacing mismatch");
    }

    /**
     * @notice After deploy, parameters struct should be reset to default
     */
    function testParametersClearedAfterDeploy() public {
        deployer.deployPublic(factory, token0, token1, fee, tickSpacing);
        (address f, address t0, address t1, uint24 f2, int24 ts) = deployer.parameters();
        assertEq(f, address(0), "Factory param not cleared");
        assertEq(t0, address(0), "Token0 param not cleared");
        assertEq(t1, address(0), "Token1 param not cleared");
        assertEq(f2, uint24(0), "Fee param not cleared");
        assertEq(ts, int24(0), "TickSpacing param not cleared");
    }

    /**
     * @notice Deploying twice with same salt should revert due to address collision
     */
    function testDeployTwiceReverts() public {
        deployer.deployPublic(factory, token0, token1, fee, tickSpacing);
        vm.expectRevert();
        deployer.deployPublic(factory, token0, token1, fee, tickSpacing);
    }
}
