// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {BaseRainterpreterExternNPE2, Operand} from "rain.interpreter/abstract/BaseRainterpreterExternNPE2.sol";
import {LibConvert} from "rain.lib.typecast/LibConvert.sol";
import {LibOpFtsoCurrentPriceUsd} from "../lib/op/LibOpFtsoCurrentPriceUsd.sol";
import {LibOpFtsoCurrentPricePair} from "../lib/op/LibOpFtsoCurrentPricePair.sol";

bytes constant INTEGRITY_FUNCTION_POINTERS = hex"0c5c0c68";
bytes constant OPCODE_FUNCTION_POINTERS = hex"086c0bbe";

uint256 constant OPCODE_FTSO_CURRENT_PRICE_USD = 0;
uint256 constant OPCODE_FTSO_CURRENT_PRICE_PAIR = 1;
uint256 constant OPCODE_FUNCTION_POINTERS_LENGTH = 2;

abstract contract FlareFtsoExtern is BaseRainterpreterExternNPE2 {
    function opcodeFunctionPointers() internal pure override returns (bytes memory) {
        return OPCODE_FUNCTION_POINTERS;
    }

    function integrityFunctionPointers() internal pure override returns (bytes memory) {
        return INTEGRITY_FUNCTION_POINTERS;
    }

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
