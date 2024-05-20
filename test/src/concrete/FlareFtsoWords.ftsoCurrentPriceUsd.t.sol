// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {OpTest} from "rain.interpreter/../test/abstract/OpTest.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {EXPRESSION_DEPLOYER_NP_META_PATH} from
    "rain.interpreter/../test/lib/constants/ExpressionDeployerNPConstants.sol";
import {BLOCK_NUMBER} from "../lib/registry/LibFlareContractRegistry.t.sol";

contract FlareFtsoWordsFtsoCurrentPriceUsdTest is OpTest {
    using Strings for address;

    function beforeOpTestConstructor() internal override {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
    }

    function testFlareFtsoWordsFtsoCurrentPriceUsdHappyFork() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        uint256[] memory expectedStack = new uint256[](1);
        expectedStack[0] = 3541.77263e18;

        checkHappy(
            bytes(
                string.concat(
                    "using-words-from ",
                    address(flareFtsoWords).toHexString(),
                    " _: ftso-current-price-usd(\"ETH\" 3600);"
                )
            ),
            expectedStack,
            "ftso-current-price-usd(\"ETH\" 3600)"
        );
    }

    function testFlareFtsoWordsFtsoCurrentPriceUnhappyZeroFork() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        checkUnhappy(
            bytes(
                string.concat(
                    "using-words-from ", address(flareFtsoWords).toHexString(), " _: ftso-current-price-usd(0 3600);"
                )
            ),
            "FTSO index not supported"
        );
    }
}
