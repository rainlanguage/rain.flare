// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {OpTest} from "rainlang-0.1.2/src/../test/abstract/OpTest.sol";
import {FlareFtsoWords} from "../../../src/concrete/FlareFtsoWords.sol";
import {LibFork} from "../../../test/fork/LibFork.sol";
import {Strings} from "@openzeppelin-contracts-5.6.1/utils/Strings.sol";
import {BLOCK_NUMBER} from "../lib/registry/LibFlareContractRegistry.t.sol";
import {UnexpectedOperand} from "rainlang-0.1.2/src/error/ErrParse.sol";

/// All three FlareFtso words are wired to `handleOperandDisallowed`, i.e. they
/// MUST reject any explicitly supplied operand at parse time. These tests pin
/// that behaviour end-to-end through the sub parser (the pointers test only
/// pins the build array, not the runtime parse behaviour).
contract FlareFtsoWordsOperandDisallowedTest is OpTest {
    using Strings for address;

    function beforeOpTestConstructor() internal override {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function checkOperandRejected(string memory body) internal {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        bytes memory rainString =
            bytes(string.concat("using-words-from ", address(flareFtsoWords).toHexString(), " ", body));
        vm.expectRevert(abi.encodeWithSelector(UnexpectedOperand.selector));
        bytes memory bytecode = I_DEPLOYER.parse2(rainString);
        (bytecode);
    }

    function testFlareFtsoWordsFtsoCurrentPriceUsdOperandDisallowed() external {
        checkOperandRejected("_: ftso-current-price-usd<0>(\"ETH\" 3600);");
    }

    function testFlareFtsoWordsFtsoCurrentPricePairOperandDisallowed() external {
        checkOperandRejected("_: ftso-current-price-pair<0>(\"ETH\" \"BTC\" 3600);");
    }

    function testFlareFtsoWordsSflrExchangeRateOperandDisallowed() external {
        checkOperandRejected("_: sflr-exchange-rate<0>();");
    }
}
