// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {FtsoTest, Operand, IFtso} from "../../../abstract/FtsoTest.sol";
import {LibOpFtsoCurrentPricePair} from "src/lib/op/LibOpFtsoCurrentPricePair.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/src/lib/LibIntOrAString.sol";
import {BLOCK_NUMBER} from "../registry/LibFlareContractRegistry.t.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {InactiveFtso} from "src/err/ErrFtso.sol";
import {LibWillOverflow} from "rain.math.fixedpoint/lib/LibWillOverflow.sol";

contract LibOpFtsoCurrentPricePairTest is FtsoTest {
    function externalRun(Operand operand, uint256[] memory inputs) external view override returns (uint256[] memory) {
        return LibOpFtsoCurrentPricePair.run(operand, inputs);
    }

    function testIntegrity(Operand operand, uint256 inputs, uint256 outputs) external {
        (uint256 calculatedInputs, uint256 calculatedOutputs) =
            LibOpFtsoCurrentPricePair.integrity(operand, inputs, outputs);
        assertEq(calculatedInputs, 3);
        assertEq(calculatedOutputs, 1);
    }

    function testRunForkHappy() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        uint256[] memory inputs = new uint256[](3);
        inputs[0] = IntOrAString.unwrap(LibIntOrAString.fromString("ETH"));
        inputs[1] = IntOrAString.unwrap(LibIntOrAString.fromString("BTC"));
        inputs[2] = 3600;
        uint256[] memory outputs = this.externalRun(Operand.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(outputs[0], 51003953997244396);

        inputs[0] = IntOrAString.unwrap(LibIntOrAString.fromString("BTC"));
        inputs[1] = IntOrAString.unwrap(LibIntOrAString.fromString("ETH"));
        outputs = this.externalRun(Operand.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(outputs[0], 19606323071619648266);
    }

    /// An inactive FTSO should revert. Tests the first symbol being inactive.
    function testRunFtsoNotActiveA(
        Operand operand,
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
        vm.assume(!LibWillOverflow.scale18WillOverflow(currentPriceB.price, currentPriceB.decimals, 0));

        warpNotStale(currentPriceB, timeout, currentTime);

        uint256 intSymbolA = IntOrAString.unwrap(LibIntOrAString.fromString(symbolA));
        uint256 intSymbolB = IntOrAString.unwrap(LibIntOrAString.fromString(symbolB));

        mockRegistry(2);
        mockFtsoRegistry(FTSO_A, symbolA);
        mockFtsoRegistry(FTSO_B, symbolB);

        activateFtso(FTSO_B);
        conformPriceDetails(priceDetailsB, currentPriceB);
        finalizePrice(priceDetailsB);
        mockPriceDetails(FTSO_B, priceDetailsB);
        mockPrice(FTSO_B, currentPriceB);

        vm.mockCall(FTSO_A, abi.encodeWithSelector(IFtso.active.selector), abi.encode(false));

        uint256[] memory inputs = new uint256[](3);
        inputs[0] = intSymbolA;
        inputs[1] = intSymbolB;
        inputs[2] = timeout;
        vm.expectRevert(abi.encodeWithSelector(InactiveFtso.selector));
        this.externalRun(operand, inputs);
    }

    /// An inactive FTSO should revert. Tests the second symbol.
    function testRunFtsoNotActiveB(Operand operand, string memory symbolA, string memory symbolB, uint256 timeout)
        external
    {
        vm.assume(bytes(symbolA).length < 0x20);
        vm.assume(bytes(symbolB).length < 0x20);
        vm.assume(keccak256(bytes(symbolA)) != keccak256(bytes(symbolB)));

        uint256 intSymbolA = IntOrAString.unwrap(LibIntOrAString.fromString(symbolA));
        uint256 intSymbolB = IntOrAString.unwrap(LibIntOrAString.fromString(symbolB));

        mockRegistry(1);
        mockFtsoRegistry(FTSO_B, symbolB);

        vm.mockCall(FTSO_B, abi.encodeWithSelector(IFtso.active.selector), abi.encode(false));

        uint256[] memory inputs = new uint256[](3);
        inputs[0] = intSymbolA;
        inputs[1] = intSymbolB;
        inputs[2] = timeout;
        vm.expectRevert(abi.encodeWithSelector(InactiveFtso.selector));
        this.externalRun(operand, inputs);
    }
}
