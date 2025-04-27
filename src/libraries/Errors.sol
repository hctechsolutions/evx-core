// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Nebular Custom Errors
/// @notice Gas-efficient, grouped error definitions for Nebular contracts
/// @dev Errors are organized to improve readability, reuse and maintenance

/// @notice Pool is currently locked (reentrancy guard triggered)
/// @dev Thrown by the `lock` modifier when reentrant entry is detected
error Locked();

/// @notice Caller is not the factory owner
/// @dev Thrown by the `onlyFactoryOwner` modifier if sender ≠ factory owner
error OnlyFactoryOwner();

/// @notice Observation initialization has already been performed
/// @dev Thrown by `initializeObservation` when slot0.sqrtPriceX96 ≠ 0
error AlreadyInitialized();

/// @notice Provided tick range is invalid: lower must be < upper
/// @dev Thrown by `checkTicks` when tickLower ≥ tickUpper
error InvalidTickOrder();

/// @notice Provided tickLower is below the minimum allowable value
/// @dev Thrown when tickLower ≤ TickMath.MIN_TICK
error TickLowerBelowMinimum();

/// @notice Provided tickUpper is above the maximum allowable value
/// @dev Thrown when tickUpper ≥ TickMath.MAX_TICK
error TickUpperAboveMaximum();

/// @notice Failed to retrieve token balance via staticcall
/// @dev Thrown by `balance0` or `balance1` on unsuccessful call or malformed return
error BalanceQueryFailed();

/// @notice Cannot snapshot cumulatives: lower tick not initialized
/// @dev Thrown by `snapshotCumulativesInside` when lower.tick.initialized = false
error LowerTickNotInitialized();

/// @notice Cannot snapshot cumulatives: upper tick not initialized
/// @dev Thrown by `snapshotCumulativesInside` when upper.tick.initialized = false
error UpperTickNotInitialized();

/// @notice Cannot mint zero liquidity; amount must be > 0
/// @dev Thrown at the start of `mint` if amount = 0
error MintZeroAmount();

/// @notice Mint operation failed: insufficient token0 balance repaid
/// @dev Thrown after callback if balance0 did not increase by required amount
error InsufficientBalance0();

/// @notice Mint operation failed: insufficient token1 balance repaid
/// @dev Thrown after callback if balance1 did not increase by required amount
error InsufficientBalance1();

/// @notice Swap operation cannot process zero amountSpecified
/// @dev Thrown at the start of `swap` if amountSpecified = 0
error ZeroSwapAmount();

/// @notice Swap operation violated sqrtPriceLimitX96 bounds
/// @dev Thrown if sqrtPriceLimitX96 is outside valid Q64.96 range or on wrong side
error SqrtPriceLimit();

/// @notice Swap operation failed: insufficient input token amount repaid
/// @dev Thrown after callback if balance did not increase by required input amount
error InsufficientInputAmount();

/// @notice Swap operation requires positive in-range liquidity
/// @dev Thrown by `swap` or `flash` when liquidity = 0
error NoLiquidity();

/// @notice Flash loan: required fee0 was not repaid
/// @dev Thrown after callback if balance0After < balance0Before + fee0
error FlashFee0NotReceived();

/// @notice Flash loan: required fee1 was not repaid
/// @dev Thrown after callback if balance1After < balance1Before + fee1
error FlashFee1NotReceived();

/// @notice Provided implementation address is the zero address
/// @dev Thrown by NebularFactory constructor if poolImplementation = address(0)
error ZeroImplementation();

/// @notice Provided token pair addresses are identical
/// @dev Thrown by `_sortTokens` or `createPool` on identical tokens
error IdenticalAddresses();

/// @notice Provided token0 or token1 address is the zero address
/// @dev Thrown by `_sortTokens` or `createPool` when token0 = address(0)
error ZeroAddress();

/// @notice Provided fee tier is not supported or enabled
/// @dev Thrown by `createPool` or `enableFeeAmount` when fee mapping = 0
error InvalidFee();

/// @notice A pool for the given token pair and fee already exists
/// @dev Thrown by `createPool` when getPool[...] ≠ address(0)
error PoolExists();

/// @notice Caller is not authorized to perform this action
/// @dev Thrown by `setOwner` or `enableFeeAmount` when msg.sender ≠ owner
error Forbidden();

/// @notice Provided fee tier exceeds the maximum allowable value
/// @dev Thrown by `enableFeeAmount` when fee ≥ 1e6
error FeeTooHigh();

/// @notice Provided tick spacing is out of valid range (0 < spacing < 16384)
/// @dev Thrown by `enableFeeAmount` when tickSpacing ≤ 0 or ≥ 16384
error InvalidTickSpacing();

/// @notice Fee tier has already been enabled with tick spacing
/// @dev Thrown by `enableFeeAmount` when fee mapping ≠ 0
error AlreadyEnabled();

/// @notice Prevents a function from being executed via delegatecall
/// @dev Thrown by NoDelegateCall modifier if call context ≠ contract address
error NoDelegateCallError();

/// @notice Provided fee protocol parameters are outside valid range
/// @dev Thrown by `setFeeProtocol` when `feeProtocol0` or `feeProtocol1` are not 0 or outside [4,10]
error InvalidFeeProtocol();