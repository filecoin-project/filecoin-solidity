// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

library Errors {
    error NonZeroExitCode(int256 exit_code, string description);

    // Exit codes
    int256 constant USR_ILLEGAL_ARGUMENT = 16;
    int256 constant USR_NOT_FOUND = 17;
    int256 constant USR_FORBIDDEN = 18;
    int256 constant USR_INSUFFICIENT_FUNDS = 19;
    int256 constant USR_ILLEGAL_STATE = 20;
    int256 constant USR_SERIALIZATION = 21;
    int256 constant USR_UNHANDLED_MESSAGE = 22;
    int256 constant USR_UNSPECIFIED = 23;
    int256 constant USR_ASSERTION_FAILED = 24;
    int256 constant START_FOR_ACTOR_SPECIFIC_EXIT_CODES = 32;

    function revertOnError(int256 exit_code) internal pure {
        if (exit_code == 0) return;

        string memory description;

        if (exit_code == USR_ILLEGAL_ARGUMENT) description = "USR_ILLEGAL_ARGUMENT: invalid message parameters";
        if (exit_code == USR_NOT_FOUND) description = "USR_NOT_FOUND: message referenced something that doesn't exist";
        if (exit_code == USR_FORBIDDEN) description = "USR_FORBIDDEN: operation forbidden";
        if (exit_code == USR_INSUFFICIENT_FUNDS) description = "USR_INSUFFICIENT_FUNDS";
        if (exit_code == USR_ILLEGAL_STATE) description = "USR_ILLEGAL_STATE: the actor is in an illegal state";
        if (exit_code == USR_SERIALIZATION) description = "USR_SERIALIZATION: actor failed to serialize or deserialize some state";
        if (exit_code == USR_UNHANDLED_MESSAGE) description = "USR_UNHANDLED_MESSAGE: actor cannot handle this message";
        if (exit_code == USR_UNSPECIFIED) description = "USR_UNSPECIFIED: the actor failed with an unspecified error";
        if (exit_code == USR_ASSERTION_FAILED) description = "USR_ASSERTION_FAILED: the actor failed some user-level assertion";

        if (exit_code > USR_ASSERTION_FAILED && exit_code < START_FOR_ACTOR_SPECIFIC_EXIT_CODES) description = "Reserved exit code";

        if (exit_code >= START_FOR_ACTOR_SPECIFIC_EXIT_CODES) description = "Actor specific exit code";

        revert NonZeroExitCode(exit_code, description);
    }
}
