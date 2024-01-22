// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {FtsoTest, Operand} from "../../../abstract/FtsoTest.sol";
import {LibOpFtsoCurrentPricePair} from "src/lib/op/LibOpFtsoCurrentPricePair.sol";
import {LibIntOrAString, IntOrAString} from "rain.intorastring/src/lib/LibIntOrAString.sol";
import {BLOCK_NUMBER} from "../registry/LibFlareContractRegistry.t.sol";
import {LibFork} from "test/fork/LibFork.sol";

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
        // ~5.94e16 BTC/ETH
        assertEq(outputs[0], 59404379770348933);

        inputs[0] = IntOrAString.unwrap(LibIntOrAString.fromString("BTC"));
        inputs[1] = IntOrAString.unwrap(LibIntOrAString.fromString("ETH"));
        outputs = this.externalRun(Operand.wrap(0), inputs);
        assertEq(outputs.length, 1);
        assertEq(outputs[0], 16833775621694806469);
    }
}
