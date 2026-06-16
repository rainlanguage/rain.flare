// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {FtsoTest, OperandV2, StackItem} from "../../../abstract/FtsoTest.sol";
import {LibOpFtsoCurrentPriceUsd} from "src/lib/op/LibOpFtsoCurrentPriceUsd.sol";
import {IFtso} from "src/lib/registry/LibFlareContractRegistry.sol";
import {LibIntOrAString, IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {BLOCK_NUMBER} from "../registry/LibFlareContractRegistry.t.sol";
import {InactiveFtso, PriceNotFinalized, StalePrice, DecimalsTooLarge} from "src/err/ErrFtso.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {
    NegativeFixedDecimalConversion,
    LossyConversionFromFloat
} from "rain-math-float-0.1.1/src/error/ErrDecimalFloat.sol";

contract LibOpFtsoCurrentPriceUsdTest is FtsoTest {
    function externalRun(OperandV2 operand, StackItem[] memory inputs)
        external
        view
        override
        returns (StackItem[] memory)
    {
        return LibOpFtsoCurrentPriceUsd.run(operand, inputs);
    }

    function testIntegrity(OperandV2 operand, uint256 inputs, uint256 outputs) external pure {
        (uint256 calculatedInputs, uint256 calculatedOutputs) =
            LibOpFtsoCurrentPriceUsd.integrity(operand, inputs, outputs);
        assertEq(calculatedInputs, 2);
        assertEq(calculatedOutputs, 1);
    }

    function testRunForkCurrentPriceHappy() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("ETH"))));
        inputs[1] = StackItem.wrap(bytes32(uint256(3600)));
        StackItem[] memory outputs = this.externalRun(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(StackItem.unwrap(outputs[0]), Float.unwrap(LibDecimalFloat.packLossless(2525.74849e5, -5)));

        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("BTC"))));
        outputs = this.externalRun(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(StackItem.unwrap(outputs[0]), Float.unwrap(LibDecimalFloat.packLossless(67694.11308e5, -5)));

        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("XRP"))));
        outputs = this.externalRun(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(StackItem.unwrap(outputs[0]), Float.unwrap(LibDecimalFloat.packLossless(0.53163e5, -5)));

        // USDT is interesting as it probably has different decimals to the
        // others, but should still get normalized to 18 decimals.
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("USDT"))));
        outputs = this.externalRun(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(StackItem.unwrap(outputs[0]), Float.unwrap(LibDecimalFloat.packLossless(0.99919e5, -5)));
    }

    function testRunHappy(
        OperandV2 operand,
        string memory symbol,
        uint256 timeout,
        uint256 currentTime,
        PriceDetails memory priceDetails,
        CurrentPrice memory currentPrice
    ) external {
        currentPrice.price = bound(currentPrice.price, 0, uint256(int256(type(int224).max)));
        currentPrice.decimals = bound(currentPrice.decimals, 0, type(uint8).max);
        vm.assume(bytes(symbol).length <= 31);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbol));

        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));
        currentTime = warpNotStale(currentPrice, timeout, currentTime);

        conformPriceDetails(priceDetails, currentPrice);
        finalizePrice(priceDetails);

        mockRegistry();
        mockFtsoRegistry(FTSO, symbol);
        activateFtso();
        mockPriceDetails(priceDetails);
        mockPrice(FTSO, currentPrice);

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(intSymbol));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        StackItem[] memory outputs = this.externalRun(operand, inputs);
        assertEq(outputs.length, 1);
        assertEq(
            StackItem.unwrap(outputs[0]),
            Float.unwrap(LibDecimalFloat.packLossless(int256(currentPrice.price), -int256(currentPrice.decimals)))
        );
    }

    /// If the decimal rescale will overflow, it should revert.
    function testRunDecimalOverflow(
        OperandV2 operand,
        string memory symbol,
        uint256 timeout,
        uint256 currentTime,
        PriceDetails memory priceDetails,
        CurrentPrice memory currentPrice
    ) external {
        vm.assume(bytes(symbol).length <= 31);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbol));
        currentPrice.decimals =
            bound(currentPrice.decimals, uint256(type(uint8).max) + 1, uint256(int256(type(int32).max)));
        currentPrice.price = bound(currentPrice.price, 0, uint256(int256(type(int224).max)));

        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));
        currentPrice.timestamp = bound(currentPrice.timestamp, 0, type(uint256).max - timeout);
        currentTime = bound(currentTime, currentPrice.timestamp, currentPrice.timestamp + timeout);
        vm.warp(currentTime);

        conformPriceDetails(priceDetails, currentPrice);
        finalizePrice(priceDetails);

        mockRegistry();
        mockFtsoRegistry(FTSO, symbol);
        activateFtso();
        mockPriceDetails(priceDetails);
        mockPrice(FTSO, currentPrice);

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(intSymbol));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        vm.expectRevert(abi.encodeWithSelector(DecimalsTooLarge.selector, currentPrice.decimals));
        this.externalRun(operand, inputs);
    }

    /// If the timestamp is too old, the price is stale.
    function testRunStale(
        OperandV2 operand,
        string memory symbol,
        uint256 timeout,
        uint256 currentTime,
        PriceDetails memory priceDetails,
        CurrentPrice memory currentPrice
    ) external {
        vm.assume(bytes(symbol).length <= 31);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbol));

        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));
        currentPrice.timestamp = bound(currentPrice.timestamp, 0, type(uint256).max - timeout - 1);
        currentTime = bound(currentTime, currentPrice.timestamp + timeout + 1, type(uint256).max);
        vm.warp(currentTime);

        conformPriceDetails(priceDetails, currentPrice);
        finalizePrice(priceDetails);

        mockRegistry();
        mockFtsoRegistry(FTSO, symbol);
        activateFtso();
        mockPriceDetails(priceDetails);
        mockPrice(FTSO, currentPrice);

        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, currentPrice.timestamp, timeout));
        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(intSymbol));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        this.externalRun(operand, inputs);
    }

    /// Anything other than WEIGHTED_MEDIAN or TRUSTED_ADDRESSES should revert
    /// as it means the price is not final.
    function testRunFtsoNotFinal(
        OperandV2 operand,
        string memory symbol,
        uint256 timeout,
        PriceDetails memory priceDetails,
        CurrentPrice memory currentPrice
    ) external {
        vm.assume(bytes(symbol).length <= 31);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbol));
        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));

        conformPriceDetails(priceDetails, currentPrice);
        vm.assume(
            !((priceDetails.priceFinalizationType == uint8(IFtso.PriceFinalizationType.WEIGHTED_MEDIAN)
                        || (priceDetails.priceFinalizationType
                                == uint8(IFtso.PriceFinalizationType.TRUSTED_ADDRESSES))))
        );

        mockRegistry();
        mockFtsoRegistry(FTSO, symbol);
        activateFtso();
        mockPriceDetails(priceDetails);

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(intSymbol));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));

        vm.expectRevert(abi.encodeWithSelector(PriceNotFinalized.selector, priceDetails.priceFinalizationType));
        this.externalRun(operand, inputs);
    }

    /// A negative Float timeout must revert with NegativeFixedDecimalConversion.
    function testRunNegativeTimeoutReverts(OperandV2 operand, string memory symbol, int256 coeff, int32 exp) external {
        vm.assume(bytes(symbol).length <= 31);
        coeff = bound(coeff, type(int224).min, -1);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbol));
        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(intSymbol));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(coeff, int256(exp))));
        vm.expectRevert(abi.encodeWithSelector(NegativeFixedDecimalConversion.selector, coeff, int256(exp)));
        this.externalRun(operand, inputs);
    }

    /// A fractional (non-integer) Float timeout must revert with LossyConversionFromFloat.
    function testRunFractionalTimeoutReverts(OperandV2 operand, string memory symbol, int256 coeff) external {
        vm.assume(bytes(symbol).length <= 31);
        coeff = bound(coeff, 1, int256(type(int224).max));
        vm.assume(coeff % 10 != 0);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbol));
        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(intSymbol));
        // exponent -1 with a non-multiple-of-10 coefficient is always fractional
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.packLossless(coeff, -1)));
        vm.expectRevert(abi.encodeWithSelector(LossyConversionFromFloat.selector, coeff, int256(-1)));
        this.externalRun(operand, inputs);
    }

    /// An inactive FTSO should revert.
    function testRunFtsoNotActive(OperandV2 operand, string memory symbol, uint256 timeout) external {
        vm.assume(bytes(symbol).length < 0x20);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbol));
        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));

        mockRegistry();
        mockFtsoRegistry(FTSO, symbol);

        vm.mockCall(FTSO, abi.encodeWithSelector(IFtso.active.selector), abi.encode(false));

        StackItem[] memory inputs = new StackItem[](2);
        inputs[0] = StackItem.wrap(bytes32(intSymbol));
        inputs[1] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        vm.expectRevert(abi.encodeWithSelector(InactiveFtso.selector));
        this.externalRun(operand, inputs);
    }
}
