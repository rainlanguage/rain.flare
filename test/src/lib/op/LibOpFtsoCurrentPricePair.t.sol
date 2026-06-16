// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {FtsoTest, OperandV2, StackItem, IFtso} from "../../../abstract/FtsoTest.sol";
import {LibOpFtsoCurrentPricePair} from "src/lib/op/LibOpFtsoCurrentPricePair.sol";
import {LibIntOrAString, IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {BLOCK_NUMBER} from "../registry/LibFlareContractRegistry.t.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {InactiveFtso, StalePrice, PriceNotFinalized, DecimalsTooLarge} from "src/err/ErrFtso.sol";
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

    /// #57 — priceB == 0 triggers DivisionByZero in the pair op; this pins the
    /// revert so a regression that silently swallows it can't ship.
    function testRunPairZeroQuotePriceReverts() external {
        uint256 intSymbolA = IntOrAString.unwrap(LibIntOrAString.fromStringV3("ETH"));
        uint256 intSymbolB = IntOrAString.unwrap(LibIntOrAString.fromStringV3("BTC"));
        uint256 timeout = 3600;

        // Non-stale warp so neither fetch is stale.
        vm.warp(100);

        // B (denominator): price=0, decimals=5, active, finalized, ts=0.
        mockRegistry(2);
        mockFtsoRegistry(FTSO_A, "ETH");
        mockFtsoRegistry(FTSO_B, "BTC");

        PriceDetails memory pdB;
        CurrentPrice memory cpB;
        cpB.price = 0;
        cpB.decimals = 5;
        cpB.timestamp = 0;
        conformPriceDetails(pdB, cpB);
        finalizePrice(pdB);
        activateFtso(FTSO_B);
        mockPriceDetails(FTSO_B, pdB);
        mockPrice(FTSO_B, cpB);

        // A (numerator): price=100, decimals=5, active, finalized, ts=0.
        PriceDetails memory pdA;
        CurrentPrice memory cpA;
        cpA.price = 100;
        cpA.decimals = 5;
        cpA.timestamp = 0;
        conformPriceDetails(pdA, cpA);
        finalizePrice(pdA);
        activateFtso(FTSO_A);
        mockPriceDetails(FTSO_A, pdA);
        mockPrice(FTSO_A, cpA);

        // priceA = fromFixedDecimalLosslessPacked(100, 5) → (coeff=100, exp=-5)
        // priceB = fromFixedDecimalLosslessPacked(0, 5) → FLOAT_ZERO (coeff=0, exp=0)
        // div(priceA, priceB) → DivisionByZero(100, -5)
        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(intSymbolA));
        inputs[1] = StackItem.wrap(bytes32(intSymbolB));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        vm.expectRevert(abi.encodeWithSelector(DivisionByZero.selector, int256(100), int256(-5)));
        this.externalRun(OperandV2.wrap(0), inputs);
    }

    /// #58 — StalePrice propagates when symbolB (denominator/first-fetched) is stale.
    function testRunStalePriceB(
        OperandV2 operand,
        string memory symbolA,
        string memory symbolB,
        uint256 timeout,
        PriceDetails memory priceDetailsB,
        CurrentPrice memory currentPriceB
    ) external {
        vm.assume(bytes(symbolA).length < 0x20);
        vm.assume(bytes(symbolB).length < 0x20);
        vm.assume(keccak256(bytes(symbolA)) != keccak256(bytes(symbolB)));

        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));
        currentPriceB.timestamp = bound(currentPriceB.timestamp, 0, type(uint256).max - timeout - 1);
        vm.warp(currentPriceB.timestamp + timeout + 1);

        currentPriceB.price = bound(currentPriceB.price, 0, uint256(int256(type(int224).max)));
        currentPriceB.decimals = bound(currentPriceB.decimals, 0, type(uint8).max);

        uint256 intSymbolA = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolA));
        uint256 intSymbolB = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolB));

        // Only symbolB is fetched before stale revert; symbolA not needed.
        mockRegistry(1);
        mockFtsoRegistry(FTSO_B, symbolB);
        activateFtso(FTSO_B);
        conformPriceDetails(priceDetailsB, currentPriceB);
        finalizePrice(priceDetailsB);
        mockPriceDetails(FTSO_B, priceDetailsB);
        mockPrice(FTSO_B, currentPriceB);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(intSymbolA));
        inputs[1] = StackItem.wrap(bytes32(intSymbolB));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, currentPriceB.timestamp, timeout));
        this.externalRun(operand, inputs);
    }

    /// #58 — StalePrice propagates when symbolA (numerator/second-fetched) is stale.
    function testRunStalePriceA(
        OperandV2 operand,
        string memory symbolA,
        string memory symbolB,
        uint256 timeout,
        PriceDetails memory priceDetailsA,
        CurrentPrice memory currentPriceA,
        PriceDetails memory priceDetailsB,
        CurrentPrice memory currentPriceB
    ) external {
        vm.assume(bytes(symbolA).length < 0x20);
        vm.assume(bytes(symbolB).length < 0x20);
        vm.assume(keccak256(bytes(symbolA)) != keccak256(bytes(symbolB)));

        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));

        // A is stale. Bound A.ts so warpTs = A.ts + timeout + 1 doesn't overflow,
        // AND so B.ts + timeout = warpTs + timeout = A.ts + 2*timeout + 1 doesn't overflow.
        // (timeout <= type(int224).max so 2*timeout fits in uint256.)
        currentPriceA.timestamp = bound(currentPriceA.timestamp, 0, type(uint256).max - 2 * timeout - 1);
        currentPriceA.price = bound(currentPriceA.price, 0, uint256(int256(type(int224).max)));
        currentPriceA.decimals = bound(currentPriceA.decimals, 0, type(uint8).max);

        uint256 warpTs = currentPriceA.timestamp + timeout + 1;
        vm.warp(warpTs);

        // B.ts = warpTs → stale check: warpTs > warpTs + timeout = false (B not stale).
        // warpTs + timeout = A.ts + 2*timeout + 1 ≤ type(uint256).max (by bound above).
        currentPriceB.timestamp = warpTs;
        currentPriceB.price = bound(currentPriceB.price, 1, uint256(int256(type(int224).max)));
        currentPriceB.decimals = bound(currentPriceB.decimals, 0, type(uint8).max);

        uint256 intSymbolA = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolA));
        uint256 intSymbolB = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolB));

        // Both symbols are fetched: B first (succeeds), then A (stale).
        mockRegistry(2);
        mockFtsoRegistry(FTSO_A, symbolA);
        mockFtsoRegistry(FTSO_B, symbolB);

        activateFtso(FTSO_B);
        conformPriceDetails(priceDetailsB, currentPriceB);
        finalizePrice(priceDetailsB);
        mockPriceDetails(FTSO_B, priceDetailsB);
        mockPrice(FTSO_B, currentPriceB);

        activateFtso(FTSO_A);
        conformPriceDetails(priceDetailsA, currentPriceA);
        finalizePrice(priceDetailsA);
        mockPriceDetails(FTSO_A, priceDetailsA);
        mockPrice(FTSO_A, currentPriceA);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(intSymbolA));
        inputs[1] = StackItem.wrap(bytes32(intSymbolB));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, currentPriceA.timestamp, timeout));
        this.externalRun(operand, inputs);
    }

    /// #58 — PriceNotFinalized propagates through the pair op when symbolB is not finalized.
    function testRunPriceNotFinalizedB(
        OperandV2 operand,
        string memory symbolA,
        string memory symbolB,
        uint256 timeout,
        PriceDetails memory priceDetailsB,
        CurrentPrice memory currentPriceB
    ) external {
        vm.assume(bytes(symbolA).length < 0x20);
        vm.assume(bytes(symbolB).length < 0x20);
        vm.assume(keccak256(bytes(symbolA)) != keccak256(bytes(symbolB)));

        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));

        uint256 intSymbolA = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolA));
        uint256 intSymbolB = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolB));

        conformPriceDetails(priceDetailsB, currentPriceB);
        vm.assume(
            !(
                priceDetailsB.priceFinalizationType == uint8(IFtso.PriceFinalizationType.WEIGHTED_MEDIAN)
                    || priceDetailsB.priceFinalizationType == uint8(IFtso.PriceFinalizationType.TRUSTED_ADDRESSES)
            )
        );

        mockRegistry(1);
        mockFtsoRegistry(FTSO_B, symbolB);
        activateFtso(FTSO_B);
        mockPriceDetails(FTSO_B, priceDetailsB);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(intSymbolA));
        inputs[1] = StackItem.wrap(bytes32(intSymbolB));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        vm.expectRevert(
            abi.encodeWithSelector(PriceNotFinalized.selector, priceDetailsB.priceFinalizationType)
        );
        this.externalRun(operand, inputs);
    }

    /// #58 — DecimalsTooLarge propagates through the pair op when symbolB has oversized decimals.
    function testRunDecimalsTooLargeB(
        OperandV2 operand,
        string memory symbolA,
        string memory symbolB,
        uint256 timeout,
        PriceDetails memory priceDetailsB,
        CurrentPrice memory currentPriceB
    ) external {
        vm.assume(bytes(symbolA).length < 0x20);
        vm.assume(bytes(symbolB).length < 0x20);
        vm.assume(keccak256(bytes(symbolA)) != keccak256(bytes(symbolB)));

        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));
        currentPriceB.decimals =
            bound(currentPriceB.decimals, uint256(type(uint8).max) + 1, uint256(int256(type(int32).max)));
        currentPriceB.price = bound(currentPriceB.price, 0, uint256(int256(type(int224).max)));
        currentPriceB.timestamp = bound(currentPriceB.timestamp, 0, type(uint256).max - timeout);
        vm.warp(bound(timeout, currentPriceB.timestamp, currentPriceB.timestamp + timeout));

        uint256 intSymbolA = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolA));
        uint256 intSymbolB = IntOrAString.unwrap(LibIntOrAString.fromStringV3(symbolB));

        conformPriceDetails(priceDetailsB, currentPriceB);
        finalizePrice(priceDetailsB);

        mockRegistry(1);
        mockFtsoRegistry(FTSO_B, symbolB);
        activateFtso(FTSO_B);
        mockPriceDetails(FTSO_B, priceDetailsB);
        mockPrice(FTSO_B, currentPriceB);

        StackItem[] memory inputs = new StackItem[](3);
        inputs[0] = StackItem.wrap(bytes32(intSymbolA));
        inputs[1] = StackItem.wrap(bytes32(intSymbolB));
        inputs[2] = StackItem.wrap(Float.unwrap(LibDecimalFloat.fromFixedDecimalLosslessPacked(timeout, 0)));
        vm.expectRevert(abi.encodeWithSelector(DecimalsTooLarge.selector, currentPriceB.decimals));
        this.externalRun(operand, inputs);
    }
}
