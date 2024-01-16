// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {Operand} from "rain.interpreter/interface/unstable/IInterpreterV2.sol";
import {IFtsoRegistry, LibFlareContractRegistry} from "../registry/LibFlareContractRegistry.sol";
import {IFtso} from "flare-smart-contracts/userInterfaces/IFtso.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/lib/LibIntOrAString.sol";
import {LibFixedPointDecimalScale} from "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";

error InactiveFtso();
error PriceNotFinalized(IFtso.PriceFinalizationType priceFinalizationType);
error StalePrice(uint256 timestamp, uint256 timeout);

library LibOpFtsoCurrentPriceUsd {
    using LibIntOrAString for IntOrAString;

    function run(Operand, uint256[] memory inputs) internal view returns (uint256[] memory) {
        IntOrAString symbol;
        uint256 timeout;
        assembly ("memory-safe") {
            symbol := mload(add(inputs, 0x20))
            timeout := mload(add(inputs, 0x40))
        }

        IFtsoRegistry ftsoRegistry = LibFlareContractRegistry.getFtsoRegistry();
        IFtso ftso = ftsoRegistry.getFtsoBySymbol(symbol.toString());

        if (!ftso.active()) {
            revert InactiveFtso();
        }

        (,, IFtso.PriceFinalizationType priceFinalizationType,,) = ftso.getCurrentPriceDetails();
        if (priceFinalizationType != IFtso.PriceFinalizationType.WEIGHTED_MEDIAN) {
            revert PriceNotFinalized(priceFinalizationType);
        }

        (uint256 price, uint256 timestamp, uint256 decimals) = ftso.getCurrentPriceWithDecimals();

        if (block.timestamp - timestamp > timeout) {
            revert StalePrice(timestamp, timeout);
        }

        // Flags are 0 i.e. round down and don't saturate (error instead).
        uint256 price18 = LibFixedPointDecimalScale.scale18(price, decimals, 0);

        uint256[] memory outputs;
        assembly ("memory-safe") {
            outputs := mload(0x40)
            mstore(0x40, add(outputs, 0x40))

            mstore(outputs, 1)
            mstore(add(outputs, 0x20), price18)
        }
        return outputs;
    }

    function integrity(Operand, uint256, uint256) internal pure returns (uint256, uint256) {
        return (2, 1);
    }
}
