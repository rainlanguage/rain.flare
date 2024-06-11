// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";

contract FlareFtsoWordsDescribedByMetaTest is Test {
    function testFlareFtsoWordsDescribedByMeta() external {
        bytes memory describedByMeta = vm.readFileBinary("meta/FlareFtsoWords.rain.meta");
        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();

        assertEq(keccak256(describedByMeta), flareFtsoWords.describedByMetaV1(), "describedByMetaV1");
    }
}
