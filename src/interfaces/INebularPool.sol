// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./pool/INebularPoolImmutables.sol";
import "./pool/INebularPoolState.sol";
import "./pool/INebularPoolDerivedState.sol";
import "./pool/INebularPoolActions.sol";
import "./pool/INebularPoolOwnerActions.sol";
import "./pool/INebularPoolEvents.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface INebularPool is
    INebularPoolImmutables,
    INebularPoolState,
    INebularPoolDerivedState,
    INebularPoolActions,
    INebularPoolOwnerActions,
    INebularPoolEvents
{

}
