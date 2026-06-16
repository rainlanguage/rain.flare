// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {FtsoTest, OperandV2, StackItem, IFtso} from "../../../abstract/FtsoTest.sol";
import {LibOpFtsoCurrentPricePair} from "src/lib/op/LibOpFtsoCurrentPricePair.sol";
import {LibIntOrAString, IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";
import {BLOCK_NUMBER} from "test/fork/ForkConstants.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {InactiveFtso} from "src/err/ErrFtso.sol";
import {LibDecimalFloat, Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

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
}
