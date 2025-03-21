// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@nebula/interfaces/IPriceOracle.sol";
import "@nebula/contracts/PositionNFT.sol";
import "@nebula/utils/MathUtils.sol";

/**
 * @title LiquidityPool
 * @notice Automated Market Maker (AMM) with Concentrated Liquidity (simplified and optimized version)
 * @dev Inspired by Uniswap V3, it allows liquidity providers to add liquidity within specific price ranges.
 */
contract LiquidityPool is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using MathUtils for uint256;

    /**
     * @dev Represents a liquidity position within the pool.
     * - `liquidity`: The amount of liquidity provided.
     * - `lowerTick`: The lower price tick at which liquidity is active.
     * - `upperTick`: The upper price tick at which liquidity is active.
     * - `entryPrice`: The price at the moment liquidity was added.
     * - `feeGrowthInsideToken0`: The accumulated fee growth for token0 within the position.
     * - `feeGrowthInsideToken1`: The accumulated fee growth for token1 within the position.
     */
    struct Position {
        uint256 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 entryPrice;
        uint256 feeGrowthInsideToken0;
        uint256 feeGrowthInsideToken1;
    }

    // Mapping of liquidity positions indexed by tokenId
    mapping(uint256 => Position) public positions;

    // Global fee accumulations (scaled by WAD for decimal precision)
    uint256 public feeGrowthGlobalToken0;
    uint256 public feeGrowthGlobalToken1;

    // Total liquidity across all positions (used for fee distribution)
    uint256 public totalLiquidity;

    // NFT representation of liquidity positions
    PositionNFT public positionNFT;

    // Addresses of the two tokens in the pool
    address public immutable token0;
    address public immutable token1;

    // Price oracle contract
    IPriceOracle public oracle;

    // Trading fee in basis points (1000 = 100%, 3 = 0.3%)
    uint256 public fee = 3;

    /**
     * @notice Emitted when liquidity is added to the pool.
     * @param user The address adding liquidity.
     * @param tokenId The ID of the newly created position.
     * @param liquidity The amount of liquidity added.
     * @param lowerTick The lower tick boundary of the position.
     * @param upperTick The upper tick boundary of the position.
     */
    event LiquidityAdded(address indexed user, uint256 tokenId, uint256 liquidity, int24 lowerTick, int24 upperTick);

    /**
     * @notice Emitted when liquidity is removed from the pool.
     * @param user The address removing liquidity.
     * @param tokenId The ID of the position being removed.
     * @param liquidity The amount of liquidity removed.
     */
    event LiquidityRemoved(address indexed user, uint256 tokenId, uint256 liquidity);

    /**
     * @notice Emitted when a token swap occurs.
     * @param user The address executing the swap.
     * @param tokenIn The token being swapped in.
     * @param amountIn The amount of tokenIn provided.
     * @param amountOut The amount of tokenOut received.
     */
    event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);

    /**
     * @notice Initializes the liquidity pool with two tokens and an oracle.
     * @param _token0 Address of the first token in the pair.
     * @param _token1 Address of the second token in the pair.
     * @param _oracle Address of the price oracle.
     */
    constructor(address _token0, address _token1, IPriceOracle _oracle) {
        require(_token0 != address(0) && _token1 != address(0), "Invalid token addresses");
        require(address(_oracle) != address(0), "Invalid oracle address");

        // Deploys the NFT contract that represents liquidity positions
        positionNFT = new PositionNFT(address(this));
        token0 = _token0;
        token1 = _token1;
        oracle = _oracle;
    }

    /**
     * @notice Calculates token amounts based on liquidity, price, and tick limits.
     * - If the normalized price (price/WAD) is ≤ lowerTick, all liquidity is converted to token0.
     * - If it is ≥ upperTick, all liquidity is converted to token1.
     * - Otherwise, the calculation follows:
     *      token0 = (liquidity * WAD) / (price + WAD)
     *      token1 = liquidity - token0
     * @param liquidity The amount of liquidity provided.
     * @param price The current price from the oracle.
     * @param lowerTick The lower tick boundary of the position.
     * @param upperTick The upper tick boundary of the position.
     * @return amountToken0 The calculated amount of token0.
     * @return amountToken1 The calculated amount of token1.
     */
    function calculateTokenAmounts(
        uint256 liquidity, 
        uint256 price, 
        int24 lowerTick, 
        int24 upperTick
    ) internal pure returns (uint256 amountToken0, uint256 amountToken1) {
        uint256 normalizedPrice = price / MathUtils.WAD; // Normalize for tick comparison
        if (normalizedPrice <= uint256(uint24(lowerTick))) {
            amountToken0 = liquidity;
            amountToken1 = 0;
        } else if (normalizedPrice >= uint256(uint24(upperTick))) {
            amountToken0 = 0;
            amountToken1 = liquidity;
        } else {
            amountToken0 = (liquidity * MathUtils.WAD) / (price + MathUtils.WAD);
            amountToken1 = liquidity - amountToken0;
        }
    }

    function claimFees(uint256 tokenId) external nonReentrant {
        require(positionNFT.ownerOf(tokenId) == msg.sender, "Not the owner");

        Position storage pos = positions[tokenId];

        uint256 feeToken0 = (pos.liquidity * (feeGrowthGlobalToken0 - pos.feeGrowthInsideToken0)) / MathUtils.WAD;
        uint256 feeToken1 = (pos.liquidity * (feeGrowthGlobalToken1 - pos.feeGrowthInsideToken1)) / MathUtils.WAD;

        require(feeToken0 > 0 || feeToken1 > 0, "No fees available");

        pos.feeGrowthInsideToken0 = feeGrowthGlobalToken0;
        pos.feeGrowthInsideToken1 = feeGrowthGlobalToken1;

        IERC20(token0).safeTransfer(msg.sender, feeToken0);
        IERC20(token1).safeTransfer(msg.sender, feeToken1);
    }

    /**
     * @notice Adds liquidity to the pool and mints an NFT representing the position.
     * @param liquidity The amount of liquidity to add.
     * @param lowerTick The lower tick boundary of the position.
     * @param upperTick The upper tick boundary of the position.
     * @return tokenId The unique identifier of the newly created position.
     */
    function addLiquidity(
        uint256 liquidity, 
        int24 lowerTick, 
        int24 upperTick
    ) external nonReentrant returns (uint256 tokenId) {
        require(liquidity > 0, "Invalid liquidity amount");
        require(lowerTick < upperTick, "lowerTick must be less than upperTick");

        uint256 price = oracle.consult();
        require(price > 0, "Oracle price unavailable");

        // Calculate token amounts based on the current price and tick limits
        (uint256 amountToken0, uint256 amountToken1) = calculateTokenAmounts(liquidity, price, lowerTick, upperTick);

        IERC20(token0).safeTransferFrom(msg.sender, address(this), amountToken0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amountToken1);

        // Mint NFT and register the position with the current global fee accumulations
        tokenId = positionNFT.mint(msg.sender, liquidity, lowerTick, upperTick);
        positions[tokenId] = Position({
            liquidity: liquidity,
            lowerTick: lowerTick,
            upperTick: upperTick,
            entryPrice: price,
            feeGrowthInsideToken0: feeGrowthGlobalToken0,
            feeGrowthInsideToken1: feeGrowthGlobalToken1
        });
        
        // Update global total liquidity
        totalLiquidity += liquidity;
        emit LiquidityAdded(msg.sender, tokenId, liquidity, lowerTick, upperTick);
        return tokenId;
    }
    /**
     * @notice Removes liquidity from the pool and burns the position NFT.
     * @param tokenId The unique identifier of the liquidity position.
     */
    function removeLiquidity(uint256 tokenId) external nonReentrant {
        require(positionNFT.ownerOf(tokenId) == msg.sender, "Not the owner");
        Position memory pos = positions[tokenId];
        require(pos.liquidity > 0, "Invalid position");
        require(pos.entryPrice > 0, "Invalid entry price");

        uint256 price = oracle.consult();
        require(price > 0, "Oracle price unavailable");

        // Calculate base token amounts
        (uint256 baseAmountToken0, uint256 baseAmountToken1) = calculateTokenAmounts(
            pos.liquidity, 
            price, 
            pos.lowerTick, 
            pos.upperTick
        );

        // Impermanent loss calculation
        uint256 p = (price * MathUtils.WAD) / pos.entryPrice;
        uint256 sqrtP = MathUtils.sqrt(p * MathUtils.WAD);
        uint256 ilFactor = MathUtils.wadMul(2 * sqrtP, MathUtils.wadMul(MathUtils.WAD, MathUtils.WAD)) / (p + MathUtils.WAD);

        uint256 amountToken0 = (baseAmountToken0 * ilFactor) / MathUtils.WAD;
        uint256 amountToken1 = (baseAmountToken1 * ilFactor) / MathUtils.WAD;

        // Calculate accumulated fees
        uint256 feeToken0 = (pos.liquidity * (feeGrowthGlobalToken0 - pos.feeGrowthInsideToken0)) / MathUtils.WAD;
        uint256 feeToken1 = (pos.liquidity * (feeGrowthGlobalToken1 - pos.feeGrowthInsideToken1)) / MathUtils.WAD;

        amountToken0 += feeToken0;
        amountToken1 += feeToken1;

        // Update global liquidity
        totalLiquidity -= pos.liquidity;

        // Remove the position
        delete positions[tokenId];

        IERC20(token0).safeTransfer(msg.sender, amountToken0);
        IERC20(token1).safeTransfer(msg.sender, amountToken1);

        emit LiquidityRemoved(msg.sender, tokenId, pos.liquidity);
    }

    /**
     * @notice Partially removes liquidity from a position.
     * @param tokenId The unique identifier of the liquidity position.
     * @param liquidityAmount The amount of liquidity to remove.
     */
    function removeLiquidityPartial(uint256 tokenId, uint256 liquidityAmount) external nonReentrant {
        require(positionNFT.ownerOf(tokenId) == msg.sender, "Not the owner");
        Position storage pos = positions[tokenId];
        require(pos.liquidity >= liquidityAmount, "Not enough liquidity");

        uint256 price = oracle.consult();
        require(price > 0, "Oracle price unavailable");

        // Update entry price based on current price
        pos.entryPrice = price;

        (uint256 baseAmountToken0, uint256 baseAmountToken1) = calculateTokenAmounts(
            liquidityAmount, 
            price, 
            pos.lowerTick, 
            pos.upperTick
        );

        uint256 p = (price * MathUtils.WAD) / pos.entryPrice;
        uint256 sqrtP = MathUtils.sqrt(p * MathUtils.WAD);
        uint256 ilFactor = (2 * sqrtP * MathUtils.WAD) / (p + MathUtils.WAD);

        uint256 amountToken0 = (baseAmountToken0 * ilFactor) / MathUtils.WAD;
        uint256 amountToken1 = (baseAmountToken1 * ilFactor) / MathUtils.WAD;

        // Calculate accumulated fees
        uint256 feeToken0 = (liquidityAmount * (feeGrowthGlobalToken0 - pos.feeGrowthInsideToken0)) / MathUtils.WAD;
        uint256 feeToken1 = (liquidityAmount * (feeGrowthGlobalToken1 - pos.feeGrowthInsideToken1)) / MathUtils.WAD;

        amountToken0 += feeToken0;
        amountToken1 += feeToken1;

        pos.liquidity -= liquidityAmount;
        totalLiquidity -= liquidityAmount;

        // Update fee accumulation for the remaining position
        pos.feeGrowthInsideToken0 = feeGrowthGlobalToken0;
        pos.feeGrowthInsideToken1 = feeGrowthGlobalToken1;

        if (pos.liquidity == 0) {
            delete positions[tokenId];
        }

        IERC20(token0).safeTransfer(msg.sender, amountToken0);
        IERC20(token1).safeTransfer(msg.sender, amountToken1);

        emit LiquidityRemoved(msg.sender, tokenId, liquidityAmount);
    }

    /**
     * @notice Swaps tokens within the pool.
     * @param tokenIn The token being exchanged.
     * @param amountIn The amount of tokenIn being swapped.
     * @return amountOut The amount of tokenOut received.
     */
    function swap(address tokenIn, uint256 amountIn) external nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid swap amount");
        require(tokenIn == token0 || tokenIn == token1, "Invalid token");

        uint256 price = oracle.consult();
        require(price > 0, "Oracle price unavailable");

        address tokenOut = (tokenIn == token0) ? token1 : token0;
        uint256 feeAmount = (amountIn * fee) / 1000;
        uint256 amountInAfterFee = amountIn - feeAmount;

        uint256 reserveIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 reserveOut = IERC20(tokenOut).balanceOf(address(this));

        require(reserveOut > 0, "Not enough liquidity");

        uint256 amountInWithFee = MathUtils.wadMul(amountInAfterFee, 997e15); // 997 / 1000 converted to WAD
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);

        require(amountOut > 0 && amountOut <= reserveOut, "Not enough liquidity");

        // Update global fee accumulation by distributing the swap fee
        if (totalLiquidity > 0) {
            if (tokenIn == token0) {
                feeGrowthGlobalToken0 += MathUtils.wadDiv(feeAmount, totalLiquidity);
            } else {
                feeGrowthGlobalToken1 += MathUtils.wadDiv(feeAmount, totalLiquidity);
            }
        }

        // Execute the swap
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }
}