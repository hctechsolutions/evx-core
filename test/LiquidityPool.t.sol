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
    address public user = address(0x123);
    
    /**
     * @dev Initial setup for contracts and approvals
     */
    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");
        oracle = new MockOracle();
        pool = new LiquidityPool(address(token0), address(token1), IPriceOracle(address(oracle)));

        token0.transfer(user, 1e22);
        token1.transfer(user, 1e22);
        vm.startPrank(user);
        token0.approve(address(pool), type(uint256).max);
        token1.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    /**
     * @dev Tests adding liquidity with a specific price range.
     * Usamos lowerTick = 1 e upperTick = 3, de forma que com preço de 2e18 (normalizado para 2) o range esteja ativo.
     */
    function testAddLiquidity() public {
        // Define um preço para o oracle antes de adicionar liquidez
        oracle.setPrice(2e18); // Preço "2" em escala 1e18
        
        vm.startPrank(user);
        uint256 tokenId = pool.addLiquidity(1e18, 1, 3);
        vm.stopPrank();

        // Desestruturação atualizada: agora a posição contém 4 valores.
        (uint256 liquidity, int24 lowerTick, int24 upperTick, uint256 entryPrice) = pool.positions(tokenId);
        assertEq(liquidity, 1e18);
        assertEq(entryPrice, 2e18);
        assertEq(lowerTick, int24(1));
        assertEq(upperTick, int24(3));
    }

    /**
     * @dev Tests the swap functionality with fee deduction.
     * Adicionamos liquidez com range [1, 3] para que ela esteja ativa.
     */
    function testSwapWithFee() public {
        // Define o preço do oracle
        oracle.setPrice(2e18); // Preço "2" em escala 1e18

        vm.startPrank(user);
        // Depositar liquidez suficiente para que haja tokens para o swap.
        // Com 3e18 de liquidez e price = 2e18:
        // amountToken0 = (3e18 * 1e18) / (2e18 + 1e18) = 1e18
        // amountToken1 = 3e18 - 1e18 = 2e18
        pool.addLiquidity(3e18, 1, 3); 

        uint256 beforeBalanceToken1 = token1.balanceOf(user);
        uint256 amountOut = pool.swap(address(token0), 1e18);
        uint256 afterBalanceToken1 = token1.balanceOf(user);
        // Cálculo esperado considerando a taxa de 0.3%:
        // expectedAmountOut = (1e18 * 2e18 * 997) / (1000 * 1e18)
        uint256 expectedAmountOut = (1e18 * 2e18 * 997) / 1000 / 1e18;

        vm.stopPrank();

        assertEq(amountOut, expectedAmountOut);
        assertEq(afterBalanceToken1 - beforeBalanceToken1, expectedAmountOut);
    }

    /**
     * @dev Tests removing liquidity and correct token return.
     * Para price constante (2e18), o fator de impermanent loss deve ser 1 (em escala 1e18).
     */
    function testRemoveLiquidity() public {
        oracle.setPrice(2e18); // Preço "2" em escala 1e18

        vm.startPrank(user);
        uint256 tokenId = pool.addLiquidity(1e18, 1, 3);
        uint256 beforeBalanceToken0 = token0.balanceOf(user);
        uint256 beforeBalanceToken1 = token1.balanceOf(user);
        pool.removeLiquidity(tokenId);
        uint256 afterBalanceToken0 = token0.balanceOf(user);
        uint256 afterBalanceToken1 = token1.balanceOf(user);
        vm.stopPrank();

        // Cálculo simplificado para price = 2e18:
        // baseAmountToken0 = (liquidity * 1e18) / (price + 1e18) = (1e18 * 1e18)/(2e18+1e18) = 1e36/3e18 = 1e18/3
        // baseAmountToken1 = liquidity - baseAmountToken0 = 1e18 - (1e18/3) = 2e18/3
        uint256 numerator = 1e18 * 1e18;
        uint256 denominator = 3 * 1e18;
        uint256 expectedToken0 = numerator / denominator;
        uint256 expectedToken1 = 1e18 - expectedToken0;

        assertEq(afterBalanceToken0 - beforeBalanceToken0, expectedToken0, "Incorrect token0 returned");
        assertEq(afterBalanceToken1 - beforeBalanceToken1, expectedToken1, "Incorrect token1 returned");
    }
}
