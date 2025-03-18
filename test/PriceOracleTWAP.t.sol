// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@nebula/interfaces/IPriceOracle.sol";
import "@nebula/contracts/PriceOracleTWAP.sol";

/**
 * @title MockOracle
 * @dev A simple mock oracle that returns a configurable price via latestPrice()
 */
contract MockOracle {
    uint256 public price;

    /**
     * @dev Sets the oracle price.
     * @param _price The price to be returned by latestPrice().
     */
    function setPrice(uint256 _price) public {
        price = _price;
    }

    /**
     * @notice Returns the latest price.
     * @return The current price.
     */
    function latestPrice() external view returns (uint256) {
        return price;
    }
}

/**
 * @title PriceOracleTWAPTest
 * @dev Unit tests for the PriceOracleTWAP contract.
 */
contract PriceOracleTWAPTest is Test {
    PriceOracleTWAP public oracleTWAP;
    MockOracle public mockOracle1;
    MockOracle public mockOracle2;

    address public owner = address(1);
    address public nonOwner = address(2);

    /**
     * @dev Sets up the test environment by deploying the PriceOracleTWAP and mock oracles.
     */
    function setUp() public {
        oracleTWAP = new PriceOracleTWAP(owner);
        mockOracle1 = new MockOracle();
        mockOracle2 = new MockOracle();
    }

    /**
     * @dev Tests adding a valid oracle configuration.
     */
    function testAddOracle() public {
        vm.prank(owner);
        oracleTWAP.addOracle(address(mockOracle1), 100, 60, 8);

        // Verify that the oracle was added correctly
        (address source, uint256 maxDeviationBps, uint256 heartbeat, uint8 decimals) = oracleTWAP.oracles(0);
        assertEq(source, address(mockOracle1));
        assertEq(maxDeviationBps, 100);
        assertEq(heartbeat, 60);
        assertEq(decimals, 8);
    }

    /**
     * @dev Tests that adding an oracle with a zero address reverts.
     */
    function testAddOracleInvalidAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid oracle address");
        oracleTWAP.addOracle(address(0), 100, 60, 8);
    }

    /**
     * @dev Tests that adding an oracle with maxDeviationBps equal to zero reverts.
     */
    function testAddOracleInvalidMaxDeviation() public {
        vm.prank(owner);
        vm.expectRevert("Max deviation must be greater than zero");
        oracleTWAP.addOracle(address(mockOracle1), 0, 60, 8);
    }

    /**
     * @dev Tests that adding an oracle with heartbeat equal to zero reverts.
     */
    function testAddOracleInvalidHeartbeat() public {
        vm.prank(owner);
        vm.expectRevert("Heartbeat must be greater than zero");
        oracleTWAP.addOracle(address(mockOracle1), 100, 0, 8);
    }

    /**
     * @dev Tests that only the owner can add oracle configurations.
     */
    function testOnlyOwnerAddOracle() public {
        vm.prank(nonOwner);
        vm.expectRevert();
        oracleTWAP.addOracle(address(mockOracle1), 100, 60, 8);
    }

    /**
     * @dev Tests the consult() function when a consensus is reached.
     *      Two oracles return valid prices and the average is calculated.
     */
    function testConsultConsensus() public {
        // Set prices in mock oracles (using 1e8 as the base unit)
        mockOracle1.setPrice(2000e8);
        mockOracle2.setPrice(2200e8);

        // Add both oracles to the TWAP contract
        vm.prank(owner);
        oracleTWAP.addOracle(address(mockOracle1), 100, 60, 8);
        vm.prank(owner);
        oracleTWAP.addOracle(address(mockOracle2), 100, 60, 8);

        // Call consult() and verify the consensus price (average of 2000e8 and 2200e8 = 2100e8)
        uint256 consensusPrice = oracleTWAP.consult();
        uint256 expectedPrice = (2000e8 + 2200e8) / 2;
        assertEq(consensusPrice, expectedPrice);
        assertEq(oracleTWAP.lastValidPrice(), expectedPrice);
    }

    /**
     * @dev Tests that consult() reverts when no consensus is reached (i.e., fewer than 2 valid oracles).
     */
    function testConsultNoConsensus() public {
        // Set a price in one oracle
        mockOracle1.setPrice(2000e8);

        // Add only one oracle to the TWAP contract
        vm.prank(owner);
        oracleTWAP.addOracle(address(mockOracle1), 100, 60, 8);

        // Expect revert due to insufficient valid oracle responses
        vm.expectRevert("No consensus reached");
        oracleTWAP.consult();
    }

    /**
     * @dev Tests that consult() reverts when one of the oracle prices deviates beyond ±5%.
     */
    function testPriceDeviation() public {
        // Set both oracles to the same price for the initial call
        mockOracle1.setPrice(2000e8);
        mockOracle2.setPrice(2000e8);

        vm.prank(owner);
        oracleTWAP.addOracle(address(mockOracle1), 100, 60, 8);
        vm.prank(owner);
        oracleTWAP.addOracle(address(mockOracle2), 100, 60, 8);

        // First consult() call should accept the prices (lastValidPrice is 0)
        uint256 consensusPrice = oracleTWAP.consult();
        assertEq(consensusPrice, 2000e8);

        // Change one oracle price to a value that deviates >5% from lastValidPrice
        mockOracle1.setPrice(3000e8);

        // Now only one oracle remains valid, so consult() should revert
        vm.expectRevert("No consensus reached");
        oracleTWAP.consult();
    }
}
