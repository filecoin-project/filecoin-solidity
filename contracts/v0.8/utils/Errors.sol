// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

/// @notice This is the library for various Errors returned from FVM.

library Errors {
    // Error codes
    int256 constant USR_ILLEGAL_ARGUMENT = 16;
    int256 constant USR_NOT_FOUND = 17;
    int256 constant USR_FORBIDDEN = 18;
    int256 constant USR_INSUFFICIENT_FUNDS = 19;
    int256 constant USR_ILLEGAL_STATE = 20;
    int256 constant USR_SERIALIZATION = 21;
    int256 constant USR_UNHANDLED_MESSAGE = 22;
    int256 constant USR_UNSPECIFIED = 23;
    int256 constant USR_ASSERTION_FAILED = 24;
    int256 constant FIRST_ACTOR_SPECIFIC_EXIT_CODE = 32;

    // Indicates a method parameter is invalid.
    error IllegalArgument();

    // Indicates a requested resource does not exist.
    error NotFound();

    // Indicates an action is not permitted.
    error Forbidden();

    // Indicates a balance of funds is insufficient.
    error UserInsufficientFunds();

    // Indicates an actor's internal state is invalid.
    error IllegalState();

    // Indicates de/serialization failure within actor code.
    error Serialization();

    // Indicates the actor cannot handle this message.
    error UnhandledMessage();

    // Indicates the actor failed with an unspecified error.
    error Unspecified();

    // Indicates the actor failed a user-level assertion
    error UserAssertionFailed();

    // Indicates expired deal
    error DealExpired();

    function revertWith(int256 exitCode) internal pure {
        if (exitCode == USR_ILLEGAL_ARGUMENT) revert USR_ILLEGAL_ARGUMENT();
        if (exitCode == USR_NOT_FOUND) revert USR_NOT_FOUND();
        if (exitCode == USR_FORBIDDEN) revert USR_FORBIDDEN();
        if (exitCode == USR_INSUFFICIENT_FUNDS) revert USR_INSUFFICIENT_FUNDS();
        if (exitCode == USR_ILLEGAL_STATE) revert USR_ILLEGAL_STATE();
        if (exitCode == USR_SERIALIZATION) revert USR_SERIALIZATION();
        if (exitCode == USR_UNHANDLED_MESSAGE) revert USR_UNHANDLED_MESSAGE();
        if (exitCode == USR_UNSPECIFIED) revert USR_UNSPECIFIED();
        if (exitCode == USR_ASSERTION_FAILED) revert USR_ASSERTION_FAILED();
        if (exitCode == FIRST_ACTOR_SPECIFIC_EXIT_CODE) revert DEAL_EXPIRED();

        revert("Unknown error code");
    }
}
