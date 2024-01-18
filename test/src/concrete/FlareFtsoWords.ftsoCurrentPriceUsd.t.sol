// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {OpTest} from "rain.interpreter/../test/util/abstract/OpTest.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {EXPRESSION_DEPLOYER_NP_META_PATH} from
    "rain.interpreter/../test/util/lib/constants/ExpressionDeployerNPConstants.sol";

contract FlareFtsoWordsFtsoCurrentPriceUsdTest is OpTest {
    using Strings for address;

    function beforeOpTestConstructor() internal override {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), 18262564);
    }

    function constructionMetaPath() internal pure override returns (string memory) {
        return string.concat("lib/rain.interpreter/", EXPRESSION_DEPLOYER_NP_META_PATH);
    }

    function testFlareFtsoWordsFtsoCurrentPriceUsdHappyFork() external {
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        uint256[] memory expectedStack = new uint256[](1);
        expectedStack[0] = 2524344570000000000000;

        checkHappy(
            bytes(
                string.concat(
                    "using-words-from ",
                    address(flareFtsoWords).toHexString(),
                    " _: ftso-current-price-usd(\"ETH\" 3600);"
                )
            ),
            expectedStack,
            "ftso-current-price-usd(\"ETH\", 3600) = 2524344570000000000000"
        );
    }
}
