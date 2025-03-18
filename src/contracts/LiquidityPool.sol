// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@nebula/interfaces/IPriceOracle.sol";

/**
 * @title LiquidityPool
 * @notice Decentralized Automated Market Maker (AMM) with price oracle integration
 * @dev Utilizes a TWAP-based oracle and prevents reentrancy attacks
 */
contract LiquidityPool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Pool reserves
    uint256 public reserve0;
    uint256 public reserve1;
    
    // Token pair
    address public immutable token0;
    address public immutable token1;
    
    // External dependencies
    IPriceOracle public oracle;
    address public dao;

    // Events
    event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed user, uint256 amount0, uint256 amount1);
    event LiquidityRemoved(address indexed user, uint256 amount0, uint256 amount1);

    // Modifier to restrict access to DAO
    modifier onlyDAO() {
        require(msg.sender == dao, "Unauthorized: DAO only");
        _;
    }

    /**
     * @notice Initializes the liquidity pool
     * @param _token0 Address of the first token in the pair
     * @param _token1 Address of the second token in the pair
     * @param _oracle Address of the price oracle contract
     * @param _dao Address of the DAO contract
     */
    constructor(
        address _token0,
        address _token1,
        IPriceOracle _oracle,
        address _dao
    ) {
        require(_token0 != address(0) && _token1 != address(0), "Invalid token address");
        require(address(_oracle) != address(0), "Invalid oracle address");
        require(_dao != address(0), "Invalid DAO address");
        
        token0 = _token0;
        token1 = _token1;
        oracle = _oracle;
        dao = _dao;
    }

    /**
     * @notice Adds liquidity to the pool
     * @param amount0 Amount of token0 to deposit
     * @param amount1 Amount of token1 to deposit
     */
    function addLiquidity(uint256 amount0, uint256 amount1) external nonReentrant {
        require(amount0 > 0 && amount1 > 0, "Invalid deposit amounts");
        
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
        
        reserve0 += amount0;
        reserve1 += amount1;
        
        emit LiquidityAdded(msg.sender, amount0, amount1);
    }

    /**
     * @notice Executes a token swap
     * @param tokenIn Address of the input token
     * @param amountIn Amount of the input token
     * @return amountOut Amount of the output token
     */
    function swap(address tokenIn, uint256 amountIn) external nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid swap amount");
        require(tokenIn == token0 || tokenIn == token1, "Invalid token");
        
        uint256 price = oracle.consult();
        require(price > 0, "Oracle price unavailable");
        
        address tokenOut = (tokenIn == token0) ? token1 : token0;
        
        // Example calculation (adjust based on actual AMM logic)
        amountOut = (amountIn * price) / (10 ** 18);
        require(amountOut > 0, "Insufficient output amount");

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
        
        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }

    /**
     * @notice Updates DAO address
     * @param newDAO New DAO contract address
     */
    function setDAO(address newDAO) external onlyDAO {
        require(newDAO != address(0), "Invalid DAO address");
        dao = newDAO;
    }
}
