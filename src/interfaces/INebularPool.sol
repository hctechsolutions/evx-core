// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./pool/INebularPoolImmutables.sol";
import "./pool/INebularPoolState.sol";
import "./pool/INebularPoolDerivedState.sol";
import "./pool/INebularPoolActions.sol";
import "./pool/INebularPoolOwnerActions.sol";
import "./pool/INebularPoolEvents.sol";

/**
 * @title The interface for a Nebular Pool
 * @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform to the ERC20 specification
 * @dev The pool interface is composed of multiple smaller interfaces for modularity: Immutables, State, DerivedState, Actions, OwnerActions, and Events
 */
interface INebularPool is
    INebularPoolImmutables,
    INebularPoolState,
    INebularPoolDerivedState,
    INebularPoolActions,
    INebularPoolOwnerActions,
    INebularPoolEvents
{
    // This interface aggregates all pool functionality; implementations must satisfy all inherited interfaces
}