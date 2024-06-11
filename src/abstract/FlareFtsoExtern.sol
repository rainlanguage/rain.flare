// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {BaseRainterpreterExternNPE2, Operand} from "rain.interpreter/abstract/BaseRainterpreterExternNPE2.sol";
import {LibConvert} from "rain.lib.typecast/LibConvert.sol";
import {LibOpFtsoCurrentPriceUsd} from "../lib/op/LibOpFtsoCurrentPriceUsd.sol";
import {LibOpFtsoCurrentPricePair} from "../lib/op/LibOpFtsoCurrentPricePair.sol";

import {INTEGRITY_FUNCTION_POINTERS, OPCODE_FUNCTION_POINTERS} from "../generated/FlareFtsoWords.pointers.sol";

/// @dev Index into the function pointers array for the current USD price.
uint256 constant OPCODE_FTSO_CURRENT_PRICE_USD = 0;
/// @dev Index into the function pointers array for the current pair price.
uint256 constant OPCODE_FTSO_CURRENT_PRICE_PAIR = 1;
/// @dev The number of function pointers in the array.
uint256 constant OPCODE_FUNCTION_POINTERS_LENGTH = 2;

/// @title FlareFtsoExtern
/// Implements the extern half of FlareFtsoWords. Responsible for translating
/// rain instructions into calls to the FlareFtso contracts. Provides a greatly
/// simplified view of FTSOs for rainlang author end users.
///
/// Handles things such as:
/// - Looking up the correct FTSO contract for a given symbol from registries.
/// - Checking finalization status of prices and rejecting if not finalized.
/// - Checking the timestamp of prices and rejecting if too old.
/// - Normalizing prices to 18 decimal fixed point.
/// - Aggregate logic for multiple FTSOs such as deriving pair prices from two
///   symbols given a shared USD denominator.
///
/// Authoring rainlang against raw extern implementations is not a good UX so
/// this is intended to be used with FlareFtsoSubParser which provides all the
/// appropriate sugar to make the externs work like native rain words.
abstract contract FlareFtsoExtern is BaseRainterpreterExternNPE2 {
    /// @inheritdoc BaseRainterpreterExternNPE2
    function opcodeFunctionPointers() internal pure override returns (bytes memory) {
        return OPCODE_FUNCTION_POINTERS;
    }

    /// @inheritdoc BaseRainterpreterExternNPE2
    function integrityFunctionPointers() internal pure override returns (bytes memory) {
        return INTEGRITY_FUNCTION_POINTERS;
    }

    /// Create a 16-bit pointer array for the opcode function pointers. This is
    /// relatively gas inefficent so it is only called during tests to cross
    /// reference against the constant values that are used at runtime.
    function buildOpcodeFunctionPointers() external pure returns (bytes memory) {
        function(Operand, uint256[] memory) internal view returns (uint256[] memory)[] memory fs = new function(Operand, uint256[] memory) internal view returns (uint256[] memory)[](
            OPCODE_FUNCTION_POINTERS_LENGTH
        );
        fs[OPCODE_FTSO_CURRENT_PRICE_USD] = LibOpFtsoCurrentPriceUsd.run;
        fs[OPCODE_FTSO_CURRENT_PRICE_PAIR] = LibOpFtsoCurrentPricePair.run;

        uint256[] memory pointers;
        assembly ("memory-safe") {
            pointers := fs
        }
        return LibConvert.unsafeTo16BitBytes(pointers);
    }

    /// Create a 16-bit pointer array for the integrity function pointers. This
    /// is relatively gas inefficent so it is only called during tests to cross
    /// reference against the constant values that are used at runtime.
    function buildIntegrityFunctionPointers() external pure returns (bytes memory) {
        function(Operand, uint256, uint256) internal pure returns (uint256, uint256)[] memory fs = new function(Operand, uint256, uint256) internal pure returns (uint256, uint256)[](
            OPCODE_FUNCTION_POINTERS_LENGTH
        );
        fs[OPCODE_FTSO_CURRENT_PRICE_USD] = LibOpFtsoCurrentPriceUsd.integrity;
        fs[OPCODE_FTSO_CURRENT_PRICE_PAIR] = LibOpFtsoCurrentPricePair.integrity;

        uint256[] memory pointers;
        assembly ("memory-safe") {
            pointers := fs
        }
        return LibConvert.unsafeTo16BitBytes(pointers);
    }
}
