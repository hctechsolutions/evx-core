// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@nebular/interfaces/IUniswapV3Pool.sol";
import "@nebular/lib/MathUtils.sol";

/**
 * @title UniswapOracle
 * @notice Fetches and normalizes token pair prices from a Uniswap V3 pool.
 * @dev Computes the price using (sqrtPriceX96)^2 / 2**192 and normalizes it to WAD (1e18).
 */
contract UniswapOracle {
    using MathUtils for uint256;

    /// @notice Address of the Uniswap V3 pool.
    IUniswapV3Pool public immutable pool;

    /// @notice Decimals of token0 and token1.
    uint8 public immutable token0Decimals;
    uint8 public immutable token1Decimals;

    /**
     * @notice Initializes the oracle with a Uniswap V3 pool address.
     * @param _poolAddress The address of the Uniswap V3 pool.
     */
    constructor(address _poolAddress) {
        require(_poolAddress != address(0), "Invalid pool address");
        pool = IUniswapV3Pool(_poolAddress);

        token0Decimals = IERC20Metadata(pool.token0()).decimals();
        token1Decimals = IERC20Metadata(pool.token1()).decimals();
    }

    /**
     * @notice Returns the normalized price of token0 in terms of token1.
     * @dev Computes price = (sqrtPriceX96^2 / 2**192) and adjusts decimals to WAD.
     * @return price The price of token0 in token1, normalized to 18 decimals.
     */
    function getPrice() external view returns (uint256 price) {
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint256 priceX96 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        price = (priceX96 * MathUtils.WAD) / (2**192);
    }
}
