// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@nebula/interfaces/IPriceOracle.sol";
import "@nebula/contracts/PositionNFT.sol";

/**
 * @title LiquidityPool
 * @notice Automated Market Maker with Concentrated Liquidity (modelo simplificado)
 *
 * OBSERVAÇÕES:
 * - Este modelo não realiza ajustes dinâmicos contínuos nas posições dos LPs conforme o preço varia.
 *   Em vez disso, os saldos dos LPs são recalculados com base no preço atual no momento de eventos (swap ou retirada).
 * - A fórmula para calcular a liquidez proporcional e o impermanent loss é simplificada e não reproduz toda a complexidade do Uniswap V3.
 */
contract LiquidityPool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Position {
        uint256 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 entryPrice; // Preço no momento de adicionar liquidez
    }

    // Mapeamento de posições por tokenId
    mapping(uint256 => Position) public positions;
    // Array com todos os tokenIds das posições para facilitar a iteração (exemplo didático)
    uint256[] public allPositionIds;
    // Mapeamentos para armazenar as taxas acumuladas para cada posição (por token)
    mapping(uint256 => uint256) public feesEarnedToken0;
    mapping(uint256 => uint256) public feesEarnedToken1;
    
    PositionNFT public positionNFT;
    
    address public immutable token0;
    address public immutable token1;
    IPriceOracle public oracle;
    uint256 public fee = 3; // 0.3% fee in basis points (1000 = 100%)

    event LiquidityAdded(address indexed user, uint256 tokenId, uint256 liquidity, int24 lowerTick, int24 upperTick);
    event LiquidityRemoved(address indexed user, uint256 tokenId, uint256 liquidity);
    event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _token0, address _token1, IPriceOracle _oracle) {
        require(_token0 != address(0) && _token1 != address(0), "Invalid token addresses");
        require(address(_oracle) != address(0), "Invalid oracle address");

        positionNFT = new PositionNFT(address(this));
        token0 = _token0;
        token1 = _token1;
        oracle = _oracle;
    }

    function addLiquidity(uint256 liquidity, int24 lowerTick, int24 upperTick) 
        external nonReentrant returns (uint256 tokenId) 
    {
        require(liquidity > 0, "Invalid liquidity amount");

        uint256 price = oracle.consult();
        require(price > 0, "Oracle price unavailable");

        // Cálculo simplificado: determina as quantidades de tokens com base no preço atual.
        uint256 amountToken0 = (liquidity * 1e18) / (price + 1e18);
        uint256 amountToken1 = liquidity - amountToken0;

        IERC20(token0).safeTransferFrom(msg.sender, address(this), amountToken0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amountToken1);

        tokenId = positionNFT.mint(msg.sender, liquidity, lowerTick, upperTick);
        // Armazena também o preço de entrada para cálculos de impermanent loss.
        positions[tokenId] = Position(liquidity, lowerTick, upperTick, price);
        allPositionIds.push(tokenId);

        emit LiquidityAdded(msg.sender, tokenId, liquidity, lowerTick, upperTick);
        return tokenId;
    }

    function removeLiquidity(uint256 tokenId) external nonReentrant {
        require(positionNFT.ownerOf(tokenId) == msg.sender, "Not the owner");
        Position memory pos = positions[tokenId];
        require(pos.liquidity > 0, "Invalid position");

        uint256 price = oracle.consult();
        // Cálculo simplificado dos tokens resgatados com base no preço atual.
        uint256 baseAmountToken0 = (pos.liquidity * 1e18) / (price + 1e18);
        uint256 baseAmountToken1 = pos.liquidity - baseAmountToken0;

        // Cálculo do fator de impermanent loss:
        // p = (price * 1e18) / entryPrice, com p escalado em 1e18
        uint256 p = (price * 1e18) / pos.entryPrice;
        // sqrtP = sqrt(p * 1e18), para manter a escala (se p == 1e18, sqrtP = 1e18)
        uint256 sqrtP = sqrt(p * 1e18);
        // ilFactor = (2 * sqrtP * 1e18) / (p + 1e18)
        // Se price == entryPrice, p == 1e18, sqrtP == 1e18 e ilFactor == 1e18 (nenhum impermanent loss)
        uint256 ilFactor = (2 * sqrtP * 1e18) / (p + 1e18);

        // Ajusta os valores para refletir o impermanent loss.
        uint256 amountToken0 = (baseAmountToken0 * ilFactor) / 1e18;
        uint256 amountToken1 = (baseAmountToken1 * ilFactor) / 1e18;

        // Adiciona as taxas acumuladas para a posição.
        amountToken0 += feesEarnedToken0[tokenId];
        amountToken1 += feesEarnedToken1[tokenId];

        positionNFT.burn(tokenId);
        delete positions[tokenId];
        delete feesEarnedToken0[tokenId];
        delete feesEarnedToken1[tokenId];

        IERC20(token0).safeTransfer(msg.sender, amountToken0);
        IERC20(token1).safeTransfer(msg.sender, amountToken1);

        emit LiquidityRemoved(msg.sender, tokenId, pos.liquidity);
    }

    function swap(address tokenIn, uint256 amountIn) external nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid swap amount");
        require(tokenIn == token0 || tokenIn == token1, "Invalid token");

        uint256 price = oracle.consult();
        require(price > 0, "Oracle price unavailable");

        address tokenOut = (tokenIn == token0) ? token1 : token0;
        uint256 feeAmount = (amountIn * fee) / 1000;
        uint256 amountInAfterFee = amountIn - feeAmount;
        amountOut = (amountInAfterFee * price) / 1e18;

        require(IERC20(tokenOut).balanceOf(address(this)) >= amountOut, "Not enough liquidity");

        // Distribuição das taxas apenas para posições com preço atual dentro do range.
        // Aqui, usamos o preço normalizado: normalizedPrice = price / 1e18.
        uint256 normalizedPrice = price / 1e18;
        uint256 totalActiveLiquidity = 0;
        uint256 len = allPositionIds.length;
        for (uint256 i = 0; i < len; i++) {
            uint256 posId = allPositionIds[i];
            Position memory pos = positions[posId];
            if (pos.liquidity > 0) { // posição ativa
                // Verifica se o preço normalizado está dentro do range da posição
                if (int256(normalizedPrice) >= pos.lowerTick && int256(normalizedPrice) <= pos.upperTick) {
                    totalActiveLiquidity += pos.liquidity;
                }
            }
        }
        if (totalActiveLiquidity > 0) {
            for (uint256 i = 0; i < len; i++) {
                uint256 posId = allPositionIds[i];
                Position memory pos = positions[posId];
                if (pos.liquidity > 0) {
                    if (int256(normalizedPrice) >= pos.lowerTick && int256(normalizedPrice) <= pos.upperTick) {
                        uint256 share = feeAmount * pos.liquidity / totalActiveLiquidity;
                        if (tokenIn == token0) {
                            feesEarnedToken0[posId] += share;
                        } else {
                            feesEarnedToken1[posId] += share;
                        }
                    }
                }
            }
        }
        
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }

    // Função interna para calcular a raiz quadrada usando o método de Babilônia
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
