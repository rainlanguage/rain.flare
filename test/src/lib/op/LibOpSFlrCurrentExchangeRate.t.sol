// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {OperandV2, StackItem} from "rain-interpreter-interface-0.1.0/src/interface/IInterpreterV4.sol";
import {LibOpSFLRCurrentExchangeRate} from "src/lib/op/LibOpSFlrCurrentExchangeRate.sol";
import {IStakedFlr} from "src/interface/IStakedFlr.sol";
import {SFLR_CONTRACT} from "src/lib/sflr/LibSceptreStakedFlare.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {CoefficientOverflow} from "rain-math-float-0.1.1/src/error/ErrDecimalFloat.sol";
import {ZeroSFLRRate} from "src/err/ErrFtso.sol";

contract LibOpSFlrCurrentExchangeRateTest is Test {
    function externalRun(OperandV2 operand, StackItem[] memory inputs) external view returns (StackItem[] memory) {
        return LibOpSFLRCurrentExchangeRate.run(operand, inputs);
    }

    function testIntegrity(OperandV2 operand, uint256 inputs, uint256 outputs) external pure {
        (uint256 calcInputs, uint256 calcOutputs) = LibOpSFLRCurrentExchangeRate.integrity(operand, inputs, outputs);
        assertEq(calcInputs, 0);
        assertEq(calcOutputs, 1);
    }

    function testRunMappingMocked(uint256 rate18) external {
        // Coefficient is stored as int224; values >= 2^223 overflow LibDecimalFloat.fromFixedDecimalLosslessPacked.
        vm.assume(rate18 > 0 && rate18 < 2 ** 223);
        vm.mockCall(
            address(SFLR_CONTRACT),
            abi.encodeWithSelector(IStakedFlr.getSharesByPooledFlr.selector, uint256(1e18)),
            abi.encode(rate18)
        );
        StackItem[] memory outputs = this.externalRun(OperandV2.wrap(0), new StackItem[](0));
        assertEq(outputs.length, 1);
        Float expected = LibDecimalFloat.fromFixedDecimalLosslessPacked(rate18, 18);
        assertEq(StackItem.unwrap(outputs[0]), Float.unwrap(expected));
    }

    /// A zero rate is REJECTED, not encoded. Zero is exactly representable as a
    /// Float, so nothing in the encoding stops the op returning FLOAT_ZERO here;
    /// what stops it is `LibSceptreStakedFlare.getSFLRPerFLR18` treating a zero
    /// exchange rate as the sFLR contract being unusable. This pins that the op
    /// PROPAGATES that revert rather than swallowing it — a distinct property
    /// from the lib-level pin, which cannot see whether this caller catches or
    /// re-encodes what the lib throws.
    function testRunRateZeroReverts() external {
        vm.mockCall(
            address(SFLR_CONTRACT),
            abi.encodeWithSelector(IStakedFlr.getSharesByPooledFlr.selector, uint256(1e18)),
            abi.encode(uint256(0))
        );
        vm.expectRevert(abi.encodeWithSelector(ZeroSFLRRate.selector));
        this.externalRun(OperandV2.wrap(0), new StackItem[](0));
    }

    /// A parity rate (1e18, i.e. exactly 1.0) is exactly representable: the op
    /// outputs 1.0 encoded as coefficient 1e18 at exponent -18.
    function testRunRateParityOne() external {
        vm.mockCall(
            address(SFLR_CONTRACT),
            abi.encodeWithSelector(IStakedFlr.getSharesByPooledFlr.selector, uint256(1e18)),
            abi.encode(uint256(1e18))
        );
        StackItem[] memory outputs = this.externalRun(OperandV2.wrap(0), new StackItem[](0));
        assertEq(outputs.length, 1);
        Float expected = LibDecimalFloat.packLossless(1e18, -18);
        assertEq(StackItem.unwrap(outputs[0]), Float.unwrap(expected));
    }

    /// A rate whose coefficient exceeds the int224 bound (>= 2^223) cannot be
    /// packed losslessly: the op reverts with CoefficientOverflow rather than
    /// flooring or truncating the value.
    function testRunRateCoefficientOverflow() external {
        // type(int224).max is 2^223 - 1, so 2^223 is the smallest rate that
        // overflows the coefficient.
        uint256 rate18 = 2 ** 223;
        vm.mockCall(
            address(SFLR_CONTRACT),
            abi.encodeWithSelector(IStakedFlr.getSharesByPooledFlr.selector, uint256(1e18)),
            abi.encode(rate18)
        );
        vm.expectRevert(abi.encodeWithSelector(CoefficientOverflow.selector, int256(2 ** 223), int256(-18)));
        this.externalRun(OperandV2.wrap(0), new StackItem[](0));
    }

    /// The extreme of the overflow region, pinned separately from the 2^223
    /// boundary above because it is the one rate that reaches the coefficient
    /// bound check through a uint256 -> int256 conversion that WRAPS: as a
    /// signed value type(uint256).max is -1, which is inside the int224 range.
    /// A bound check performed after that conversion would therefore accept it
    /// and emit a NEGATIVE exchange rate of -1e-18 instead of reverting, and no
    /// test at 2^223 can distinguish the two implementations. The revert is
    /// pinned by error class rather than by arguments: which coefficient the
    /// error reports for a wrapped input is the library's to choose, but that
    /// it refuses the input at all is the property this op depends on.
    function testRunRateMaxUintOverflow() external {
        vm.mockCall(
            address(SFLR_CONTRACT),
            abi.encodeWithSelector(IStakedFlr.getSharesByPooledFlr.selector, uint256(1e18)),
            abi.encode(type(uint256).max)
        );
        vm.expectRevert(CoefficientOverflow.selector);
        this.externalRun(OperandV2.wrap(0), new StackItem[](0));
    }
}
