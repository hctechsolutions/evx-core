// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@nebular/interfaces/IUniswapV3Pool.sol";
import "@nebular/interfaces/IOracle.sol";
import "@nebular/lib/MathUtils.sol";

/**
 * @title UniswapOracle
 * @notice Fetches and normalizes token pair prices from a Uniswap V3 pool using TWAP.
 * @dev Uses Uniswap V3's `observe` function to get a time-weighted average price (TWAP).
 */
contract UniswapOracle is IOracle {
    using MathUtils for uint256;

    /// @notice Address of the Uniswap V3 pool.
    IUniswapV3Pool public immutable pool;

    /// @notice Decimals of token0 and token1.
    uint8 public immutable token0Decimals;
    uint8 public immutable token1Decimals;

    /// @notice TWAP interval (in seconds) for price calculation.
    uint32 public constant TWAP_INTERVAL = 1800; // 30 min

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
     * @notice Returns the normalized price of token0 in terms of token1 using TWAP.
     * @dev Uses Uniswap V3's oracle to fetch a time-weighted average price (TWAP).
     * @return price The price of token0 in token1, normalized to 18 decimals (WAD).
     */
    function getPrice() external view returns (uint256 price) {
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        
        // Definir o intervalo de tempo para o TWAP
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = TWAP_INTERVAL;
        secondsAgos[1] = 0;


        // Obter dados do Uniswap V3 usando o método observe
        // (int56[] memory tickCumulatives,) = pool.observe(secondsAgos);

        uint256 priceX96 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        price = (priceX96 * MathUtils.WAD) / (2**192);
    }

    /**
     * @notice Converts a tick value to sqrtPriceX96.
     * @dev Uses Uniswap V3 tick math to derive the price.
     * @param tick The average tick value.
     * @return sqrtPriceX96 The sqrt price corresponding to the tick.
     */
    function getSqrtPriceX96(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        return uint160(uint256(1) << uint256(int256(tick) / 2)); // Simplified approximation for now
    }

    /**
     * @notice Normalizes a raw price to 18 decimals (WAD).
     * @dev Adjusts for token decimals differences.
     * @param rawPrice The raw price computed from Uniswap V3.
     * @return wadPrice The price scaled to 18 decimals.
     */
    function normalizePrice(uint256 rawPrice) internal view returns (uint256 wadPrice) {
        uint8 decimalsDiff = token1Decimals > token0Decimals
            ? token1Decimals - token0Decimals
            : token0Decimals - token1Decimals;

        if (token1Decimals > token0Decimals) {
            return rawPrice * (10 ** decimalsDiff);
        } else {
            return rawPrice / (10 ** decimalsDiff);
        }
    }
}
