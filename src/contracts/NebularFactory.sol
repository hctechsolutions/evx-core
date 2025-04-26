// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@nebular/interfaces/INebularFactory.sol";
import "@nebular/contracts/NoDelegateCall.sol";
import "@nebular/contracts/NebularPool.sol";

contract NebularFactory is INebularFactory, NoDelegateCall {
    using Clones for address;

    /// @inheritdoc INebularFactory
    address public override owner;

    /// @inheritdoc INebularFactory
    mapping(uint24 => int24) public override feeAmountTickSpacing;

    /// @inheritdoc INebularFactory
    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

    address public immutable poolImplementation;
    
    /**
     * @notice Initializes the factory setting deployer as owner and default fee tiers
     * @dev Emits OwnerChanged from zero address and FeeAmountEnabled for each default tier
     */
    constructor(address _poolImplementation) {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[500] = 10;
        feeAmountTickSpacing[3000] = 60;
        feeAmountTickSpacing[10000] = 200;
        
        emit FeeAmountEnabled(500, 10);
        emit FeeAmountEnabled(3000, 60);
        emit FeeAmountEnabled(10000, 200);

        require(_poolImplementation != address(0), "Zero impl");
        poolImplementation = _poolImplementation;
    }

    /**
     * @notice Sort two token addresses to ensure token0 < token1
     * @dev Throws if the tokens are identical or if either is the zero address.
     * @param tokenA One of the two tokens
     * @param tokenB The other token
     * @return token0 The smaller of the two addresses
     * @return token1 The larger of the two addresses
     */
    function _sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "Nebular: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB 
            ? (tokenA, tokenB) 
            : (tokenB, tokenA);
        require(token0 != address(0), "Nebular: ZERO_ADDRESS");
    }

    /// @inheritdoc INebularFactory
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override noDelegateCall returns (address pool) {
        require(tokenA != tokenB, "CreatePool: IDENTICAL_ADDRESSES");

        (address token0, address token1) = _sortTokens(tokenA, tokenB);

        require(token0 != address(0), "CreatePool: ZERO_ADDRESS");

        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0, "CreatePool: INVALID_FEE");

        require(getPool[token0][token1][fee] == address(0), "CreatePool: POOL_EXISTS");

        bytes32 salt = keccak256(abi.encodePacked(token0, token1, fee));

        pool = poolImplementation.cloneDeterministic(salt);
        NebularPool(pool).initialize(
            address(this), 
            token0, 
            token1, 
            fee, 
            tickSpacing
        );

        // Store pool address for both token pair orderings
        getPool[token0][token1][fee] = pool;
        getPool[token1][token0][fee] = pool;

        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    /// @inheritdoc INebularFactory
    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc INebularFactory
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner);
        require(fee < 1000000);
        // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        // 16384 ticks represents a >5x price change with ticks of 1 bips
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }
}
