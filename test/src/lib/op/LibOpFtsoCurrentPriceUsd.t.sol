// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {FtsoTest, Operand} from "../../../abstract/FtsoTest.sol";
import {LibOpFtsoCurrentPriceUsd} from "src/lib/op/LibOpFtsoCurrentPriceUsd.sol";
import {
    IFtsoRegistry,
    LibFlareContractRegistry,
    FLARE_CONTRACT_REGISTRY,
    FTSO_REGISTRY_NAME,
    IFlareContractRegistry
} from "src/lib/registry/LibFlareContractRegistry.sol";
import {LibFixedPointDecimalScale} from "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";
import {LibWillOverflow} from "rain.math.fixedpoint/lib/LibWillOverflow.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/lib/LibIntOrAString.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {BLOCK_NUMBER} from "../registry/LibFlareContractRegistry.t.sol";
import {IFtso} from "flare-smart-contracts/userInterfaces/IFtso.sol";
import {InactiveFtso, PriceNotFinalized, StalePrice, InconsistentFtso} from "src/err/ErrFtso.sol";

contract LibOpFtsoCurrentPriceUsdTest is FtsoTest {
    function externalRun(Operand operand, uint256[] memory inputs) external view override returns (uint256[] memory) {
        return LibOpFtsoCurrentPriceUsd.run(operand, inputs);
    }

    function testIntegrity(Operand operand, uint256 inputs, uint256 outputs) external pure {
        (uint256 calculatedInputs, uint256 calculatedOutputs) =
            LibOpFtsoCurrentPriceUsd.integrity(operand, inputs, outputs);
        assertEq(calculatedInputs, 2);
        assertEq(calculatedOutputs, 1);
    }

    function testRunForkCurrentPriceHappy() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        uint256[] memory inputs = new uint256[](2);
        inputs[0] = IntOrAString.unwrap(LibIntOrAString.fromString2("ETH"));
        inputs[1] = 3600;
        uint256[] memory outputs = this.externalRun(Operand.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(outputs[0], 2525.74849e18);

        inputs[0] = IntOrAString.unwrap(LibIntOrAString.fromString2("BTC"));
        outputs = this.externalRun(Operand.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(outputs[0], 67694.11308e18);

        inputs[0] = IntOrAString.unwrap(LibIntOrAString.fromString2("XRP"));
        outputs = this.externalRun(Operand.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(outputs[0], 0.53163e18);

        // USDT is interesting as it probably has different decimals to the
        // others, but should still get normalized to 18 decimals.
        inputs[0] = IntOrAString.unwrap(LibIntOrAString.fromString2("USDT"));
        outputs = this.externalRun(Operand.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(outputs[0], 0.99919e18);
    }

    function testRunHappy(
        Operand operand,
        string memory symbol,
        uint256 timeout,
        uint256 currentTime,
        PriceDetails memory priceDetails,
        CurrentPrice memory currentPrice
    ) external {
        vm.assume(bytes(symbol).length <= 31);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromString2(symbol));
        vm.assume(!LibWillOverflow.scale18WillOverflow(currentPrice.price, currentPrice.decimals, 0));

        currentTime = warpNotStale(currentPrice, timeout, currentTime);

        conformPriceDetails(priceDetails, currentPrice);
        finalizePrice(priceDetails);

        mockRegistry();
        mockFtsoRegistry(FTSO, symbol);
        activateFtso();
        mockPriceDetails(priceDetails);
        mockPrice(FTSO, currentPrice);

        uint256[] memory inputs = new uint256[](2);
        inputs[0] = intSymbol;
        inputs[1] = timeout;
        uint256[] memory outputs = this.externalRun(operand, inputs);
        assertEq(outputs.length, 1);
        assertEq(outputs[0], LibFixedPointDecimalScale.scale18(currentPrice.price, currentPrice.decimals, 0));
    }

    /// If the decimal rescale will overflow, it should revert.
    function testRunDecimalOverflow(
        Operand operand,
        string memory symbol,
        uint256 timeout,
        uint256 currentTime,
        PriceDetails memory priceDetails,
        CurrentPrice memory currentPrice
    ) external {
        vm.assume(bytes(symbol).length <= 31);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromString2(symbol));
        vm.assume(LibWillOverflow.scale18WillOverflow(currentPrice.price, currentPrice.decimals, 0));

        // timeout = bound(timeout, 1, type(uint256).max);
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

        vm.expectRevert();
        uint256[] memory inputs = new uint256[](2);
        inputs[0] = intSymbol;
        inputs[1] = timeout;
        this.externalRun(operand, inputs);
    }

    /// If the timestamp is too old, the price is stale.
    function testRunStale(
        Operand operand,
        string memory symbol,
        uint256 timeout,
        uint256 currentTime,
        PriceDetails memory priceDetails,
        CurrentPrice memory currentPrice
    ) external {
        vm.assume(bytes(symbol).length <= 31);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromString2(symbol));

        timeout = bound(timeout, 0, type(uint256).max - 2);
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
        uint256[] memory inputs = new uint256[](2);
        inputs[0] = intSymbol;
        inputs[1] = timeout;
        this.externalRun(operand, inputs);
    }

    /// Anything other than WEIGHTED_MEDIAN or TRUSTED_ADDRESSES should revert
    /// as it means the price is not final.
    function testRunFtsoNotFinal(
        Operand operand,
        string memory symbol,
        uint256 timeout,
        PriceDetails memory priceDetails,
        CurrentPrice memory currentPrice
    ) external {
        vm.assume(bytes(symbol).length <= 31);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromString2(symbol));

        conformPriceDetails(priceDetails, currentPrice);
        vm.assume(
            !(
                (
                    priceDetails.priceFinalizationType == uint8(IFtso.PriceFinalizationType.WEIGHTED_MEDIAN)
                        || (priceDetails.priceFinalizationType == uint8(IFtso.PriceFinalizationType.TRUSTED_ADDRESSES))
                )
            )
        );

        mockRegistry();
        mockFtsoRegistry(FTSO, symbol);
        activateFtso();
        mockPriceDetails(priceDetails);

        uint256[] memory inputs = new uint256[](2);
        inputs[0] = intSymbol;
        inputs[1] = timeout;

        vm.expectRevert(abi.encodeWithSelector(PriceNotFinalized.selector, priceDetails.priceFinalizationType));
        this.externalRun(operand, inputs);
    }

    /// An inactive FTSO should revert.
    function testRunFtsoNotActive(Operand operand, string memory symbol, uint256 timeout) external {
        vm.assume(bytes(symbol).length < 0x20);
        uint256 intSymbol = IntOrAString.unwrap(LibIntOrAString.fromString2(symbol));

        mockRegistry();
        mockFtsoRegistry(FTSO, symbol);

        vm.mockCall(FTSO, abi.encodeWithSelector(IFtso.active.selector), abi.encode(false));

        uint256[] memory inputs = new uint256[](2);
        inputs[0] = intSymbol;
        inputs[1] = timeout;
        vm.expectRevert(abi.encodeWithSelector(InactiveFtso.selector));
        this.externalRun(operand, inputs);
    }
}
