// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {Operand} from "rain.interpreter/interface/unstable/IInterpreterV2.sol";
import {
    LibFixedPointDecimalArithmeticOpenZeppelin,
    Math
} from "rain.math.fixedpoint/lib/LibFixedPointDecimalArithmeticOpenZeppelin.sol";
import {LibOpFtsoCurrentPriceUsd} from "./LibOpFtsoCurrentPriceUsd.sol";

library LibOpFtsoCurrentPricePair {
    function run(Operand operand, uint256[] memory inputs) internal view returns (uint256[] memory) {
        uint256 symbolA;
        assembly ("memory-safe") {
            inputs := add(inputs, 0x20)
            symbolA := mload(inputs)
            mstore(inputs, 2)
        }
        uint256[] memory outputsB = LibOpFtsoCurrentPriceUsd.run(operand, inputs);
        assembly ("memory-safe") {
            mstore(add(inputs, 0x20), symbolA)
        }
        uint256[] memory outputsA = LibOpFtsoCurrentPriceUsd.run(operand, inputs);

        uint256 priceA18;
        uint256 priceB18;
        assembly ("memory-safe") {
            priceA18 := mload(add(outputsA, 0x20))
            priceB18 := mload(add(outputsB, 0x20))
        }

        uint256 pricePair18 =
            LibFixedPointDecimalArithmeticOpenZeppelin.fixedPointDiv(priceA18, priceB18, Math.Rounding.Down);
        assembly ("memory-safe") {
            mstore(add(outputsA, 0x20), pricePair18)
        }
        return outputsA;
    }

    function integrity(Operand, uint256, uint256) internal pure returns (uint256, uint256) {
        return (3, 1);
    }
}
