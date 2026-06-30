// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {FtsoTest, OperandV2, StackItem, IFtso} from "../../../abstract/FtsoTest.sol";
import {LibOpFtsoCurrentPricePair} from "src/lib/op/LibOpFtsoCurrentPricePair.sol";
import {LibIntOrAString, IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {BLOCK_NUMBER} from "../registry/LibFlareContractRegistry.t.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {InactiveFtso, StalePrice, PriceNotFinalized} from "src/err/ErrFtso.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";
import {DivisionByZero} from "rain-math-float-0.1.1/src/error/ErrDecimalFloat.sol";

contract LibOpFtsoCurrentPricePairTest is FtsoTest {
    function externalRun(OperandV2 operand, StackItem[] memory inputs)
        external
        view
        override
        returns (StackItem[] memory)
    {
        return LibOpFtsoCurrentPricePair.run(operand, inputs);
    }

    /// Fully mock a single FTSO (registry lookup, active flag, finalized price
    /// details and the price-with-decimals tuple) with a fixed, non-stale price
    /// so a pair run is deterministic and fork-independent. `currentTime` is
    /// assumed already warped to a value at which `priceTimestamp` is not stale.
    function mockOneFtso(address ftso, string memory symbol, uint256 price, uint256 decimals, uint256 priceTimestamp)
        internal
    {
        mockFtsoRegistry(ftso, symbol);
        activateFtso(ftso);

        PriceDetails memory priceDetails;
        priceDetails.price = price;
        priceDetails.priceTimestamp = priceTimestamp;
        priceDetails.priceFinalizationType = uint8(IFtso.PriceFinalizationType.WEIGHTED_MEDIAN);
        priceDetails.lastPriceEpochFinalizationType = uint8(IFtso.PriceFinalizationType.WEIGHTED_MEDIAN);
        mockPriceDetails(ftso, priceDetails);

        CurrentPrice memory currentPrice;
        currentPrice.price = price;
        currentPrice.timestamp = priceTimestamp;
        currentPrice.decimals = decimals;
        mockPrice(ftso, currentPrice);
    }

    /// A fully-mocked, deterministic pair run. Pins that the derived price is
    /// exactly base/quote = symbolA-price / symbolB-price, with each USD price
    /// normalized by its own (independent) decimals before the division. Uses
    /// distinct decimals per leg so a swapped numerator/denominator or a
    /// mis-aligned decimal would change the result.
    function testRunPairDerivationExact() external {
        // base: 2000 with 2 decimals => 20.00
        // quote: 4 with 3 decimals  => 0.004
        // derived = 20 / 0.004 = 5000
        uint256 priceTimestamp = 1000;
        vm.warp(priceTimestamp + 10);

        mockRegistry(2);
        mockOneFtso(FTSO_A, "AAA", 2000, 2, priceTimestamp);
        mockOneFtso(FTSO_B, "BBB", 4, 3, priceTimestamp);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("AAA"))));
        inputs[1] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("BBB"))));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(3600, 0)));

        StackItem[] memory outputs = this.externalRun(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(
            StackItem.unwrap(outputs[0]),
            Float.unwrap(
                LibDecimalFloat.div(LibDecimalFloat.packLossless(20e18, -18), LibDecimalFloat.packLossless(4e15, -18))
            )
        );
        // Sanity: the derived value is numerically 5000.
        assertTrue(LibDecimalFloat.eq(Float.wrap(StackItem.unwrap(outputs[0])), LibDecimalFloat.packLossless(5000, 0)));
    }

    /// A zero base (first symbol) price yields a derived price of exactly zero,
    /// since 0 / quote = 0.
    function testRunPairZeroBaseIsZero() external {
        uint256 priceTimestamp = 1000;
        vm.warp(priceTimestamp + 10);

        mockRegistry(2);
        mockOneFtso(FTSO_A, "AAA", 0, 2, priceTimestamp);
        mockOneFtso(FTSO_B, "BBB", 4, 3, priceTimestamp);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("AAA"))));
        inputs[1] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("BBB"))));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(3600, 0)));

        StackItem[] memory outputs = this.externalRun(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertTrue(LibDecimalFloat.isZero(Float.wrap(StackItem.unwrap(outputs[0]))));
    }

    /// A zero quote (second symbol) price MUST revert with DivisionByZero rather
    /// than produce a garbage or infinite derived price. The quote is the
    /// denominator, so its zeroing is the dangerous case.
    function testRunPairZeroQuoteReverts() external {
        uint256 priceTimestamp = 1000;
        vm.warp(priceTimestamp + 10);

        mockRegistry(2);
        mockOneFtso(FTSO_A, "AAA", 2000, 2, priceTimestamp);
        mockOneFtso(FTSO_B, "BBB", 0, 3, priceTimestamp);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("AAA"))));
        inputs[1] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("BBB"))));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(3600, 0)));

        // The error carries the numerator (base price) coefficient/exponent:
        // base price 2000 with 2 decimals => (2000, -2).
        vm.expectRevert(abi.encodeWithSelector(DivisionByZero.selector, int256(2000), int256(-2)));
        this.externalRun(OperandV2.wrap(0), inputs);
    }

    /// A stale symbolB (denominator, first inner fetch) must propagate StalePrice
    /// through the pair op's memory-manipulation trampoline.
    /// Only symbolB is mocked — symbolA is never reached so activateFtso(FTSO_A)
    /// must not be called (it would add an unfulfilled vm.expectCall).
    function testRunPairStalePriceFirstLeg() external {
        uint256 priceTimestamp = 1000;
        uint256 timeout = 3600;
        vm.warp(priceTimestamp + timeout + 1);

        mockRegistry(1);  // only one registry lookup (for symbolB); symbolA never reached
        mockOneFtso(FTSO_B, "BBB", 4, 3, priceTimestamp);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("AAA"))));
        inputs[1] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("BBB"))));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));

        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, priceTimestamp, timeout));
        this.externalRun(OperandV2.wrap(0), inputs);
    }

    /// A stale symbolA (numerator, second inner fetch) must propagate StalePrice
    /// even after symbolB was successfully fetched.
    function testRunPairStalePriceSecondLeg() external {
        uint256 priceTimestampA = 1000;
        uint256 priceTimestampB = 5000;
        uint256 timeout = 3600;
        // Warp so symbolA is stale (4601 > 1000+3600) but symbolB is fresh (4601 < 5000+3600).
        vm.warp(priceTimestampA + timeout + 1);

        mockRegistry(2);
        mockOneFtso(FTSO_A, "AAA", 2000, 2, priceTimestampA);
        mockOneFtso(FTSO_B, "BBB", 4, 3, priceTimestampB);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("AAA"))));
        inputs[1] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("BBB"))));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));

        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, priceTimestampA, timeout));
        this.externalRun(OperandV2.wrap(0), inputs);
    }

    /// A non-finalized symbolB (denominator, first inner fetch) must propagate
    /// PriceNotFinalized through the pair op's trampoline.
    /// Only symbolB is mocked — symbolA is never reached.
    function testRunPairNotFinalFirstLeg() external {
        uint256 priceTimestamp = 1000;
        vm.warp(priceTimestamp + 10);

        mockRegistry(1);  // only one registry lookup (for symbolB); symbolA never reached
        mockFtsoRegistry(FTSO_B, "BBB");
        activateFtso(FTSO_B);

        // symbolB (first fetch): NOT_FINALIZED — revert before currentPrice is even fetched
        PriceDetails memory priceDetailsB;
        priceDetailsB.price = 4;
        priceDetailsB.priceTimestamp = priceTimestamp;
        priceDetailsB.priceFinalizationType = uint8(IFtso.PriceFinalizationType.NOT_FINALIZED);
        priceDetailsB.lastPriceEpochFinalizationType = uint8(IFtso.PriceFinalizationType.NOT_FINALIZED);
        mockPriceDetails(FTSO_B, priceDetailsB);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("AAA"))));
        inputs[1] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("BBB"))));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(3600, 0)));

        vm.expectRevert(
            abi.encodeWithSelector(PriceNotFinalized.selector, IFtso.PriceFinalizationType.NOT_FINALIZED)
        );
        this.externalRun(OperandV2.wrap(0), inputs);
    }

    /// A non-finalized symbolA (numerator, second inner fetch) must propagate
    /// PriceNotFinalized even after symbolB was successfully fetched.
    function testRunPairNotFinalSecondLeg() external {
        uint256 priceTimestamp = 1000;
        vm.warp(priceTimestamp + 10);

        mockRegistry(2);
        mockFtsoRegistry(FTSO_A, "AAA");
        mockFtsoRegistry(FTSO_B, "BBB");
        activateFtso(FTSO_A);
        activateFtso(FTSO_B);

        // symbolB (first fetch): properly finalized
        PriceDetails memory priceDetailsB;
        priceDetailsB.price = 4;
        priceDetailsB.priceTimestamp = priceTimestamp;
        priceDetailsB.priceFinalizationType = uint8(IFtso.PriceFinalizationType.WEIGHTED_MEDIAN);
        priceDetailsB.lastPriceEpochFinalizationType = uint8(IFtso.PriceFinalizationType.WEIGHTED_MEDIAN);
        mockPriceDetails(FTSO_B, priceDetailsB);
        CurrentPrice memory currentPriceB;
        currentPriceB.price = 4;
        currentPriceB.timestamp = priceTimestamp;
        currentPriceB.decimals = 3;
        mockPrice(FTSO_B, currentPriceB);

        // symbolA (second fetch): NOT_FINALIZED
        PriceDetails memory priceDetailsA;
        priceDetailsA.price = 2000;
        priceDetailsA.priceTimestamp = priceTimestamp;
        priceDetailsA.priceFinalizationType = uint8(IFtso.PriceFinalizationType.NOT_FINALIZED);
        priceDetailsA.lastPriceEpochFinalizationType = uint8(IFtso.PriceFinalizationType.NOT_FINALIZED);
        mockPriceDetails(FTSO_A, priceDetailsA);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("AAA"))));
        inputs[1] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("BBB"))));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(3600, 0)));

        vm.expectRevert(
            abi.encodeWithSelector(PriceNotFinalized.selector, IFtso.PriceFinalizationType.NOT_FINALIZED)
        );
        this.externalRun(OperandV2.wrap(0), inputs);
    }

    function testIntegrity(OperandV2 operand, uint256 inputs, uint256 outputs) external pure {
        (uint256 calculatedInputs, uint256 calculatedOutputs) =
            LibOpFtsoCurrentPricePair.integrity(operand, inputs, outputs);
        assertEq(calculatedInputs, 3);
        assertEq(calculatedOutputs, 1);
    }

    function testRunCurrentPricePairForkHappy() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("ETH"))));
        inputs[1] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("BTC"))));
        inputs[2] = StackItem.wrap(bytes32(uint256(3600)));
        StackItem[] memory outputs = this.externalRun(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(
            StackItem.unwrap(outputs[0]),
            Float.unwrap(
                LibDecimalFloat.packLossless(
                    0.03731119849395329429139187416029293517999955454915312408433138156716e68, -68
                )
            )
        );

        inputs[0] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("BTC"))));
        inputs[1] = StackItem.wrap(bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3("ETH"))));
        outputs = this.externalRun(OperandV2.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(
            StackItem.unwrap(outputs[0]),
            Float.unwrap(
                LibDecimalFloat.packLossless(
                    26.80160488980436844683612975257089038188438152842367927140678999277e65, -65
                )
            )
        );
    }

    /// An inactive FTSO should revert. Tests the first symbol being inactive.
    function testRunFtsoNotActiveA(
        OperandV2 operand,
        string memory symbolA,
        string memory symbolB,
        uint256 timeout,
        uint256 currentTime,
        PriceDetails memory priceDetailsB,
        CurrentPrice memory currentPriceB
    ) external {
        vm.assume(bytes(symbolA).length < 0x20);
        vm.assume(bytes(symbolB).length < 0x20);
        vm.assume(keccak256(bytes(symbolA)) != keccak256(bytes(symbolB)));
        currentPriceB.price = bound(currentPriceB.price, 0, uint256(int256(type(int224).max)));
        currentPriceB.decimals = bound(currentPriceB.decimals, 0, type(uint8).max);

        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));
        warpNotStale(currentPriceB, timeout, currentTime);

        uint256 intSymbolA = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolA));
        uint256 intSymbolB = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolB));

        mockRegistry(2);
        mockFtsoRegistry(FTSO_A, symbolA);
        mockFtsoRegistry(FTSO_B, symbolB);

        activateFtso(FTSO_B);
        conformPriceDetails(priceDetailsB, currentPriceB);
        finalizePrice(priceDetailsB);
        mockPriceDetails(FTSO_B, priceDetailsB);
        mockPrice(FTSO_B, currentPriceB);

        vm.mockCall(FTSO_A, abi.encodeWithSelector(IFtso.active.selector), abi.encode(false));

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(intSymbolA));
        inputs[1] = StackItem.wrap(bytes32(intSymbolB));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        vm.expectRevert(abi.encodeWithSelector(InactiveFtso.selector));
        this.externalRun(operand, inputs);
    }

    /// An inactive FTSO should revert. Tests the second symbol.
    function testRunFtsoNotActiveB(OperandV2 operand, string memory symbolA, string memory symbolB, uint256 timeout)
        external
    {
        vm.assume(bytes(symbolA).length < 0x20);
        vm.assume(bytes(symbolB).length < 0x20);
        vm.assume(keccak256(bytes(symbolA)) != keccak256(bytes(symbolB)));

        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));

        uint256 intSymbolA = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolA));
        uint256 intSymbolB = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolB));

        mockRegistry(1);
        mockFtsoRegistry(FTSO_B, symbolB);

        vm.mockCall(FTSO_B, abi.encodeWithSelector(IFtso.active.selector), abi.encode(false));

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(intSymbolA));
        inputs[1] = StackItem.wrap(bytes32(intSymbolB));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        vm.expectRevert(abi.encodeWithSelector(InactiveFtso.selector));
        this.externalRun(operand, inputs);
    }
}
