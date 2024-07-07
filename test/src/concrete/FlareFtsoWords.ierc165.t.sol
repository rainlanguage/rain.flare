// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {IInterpreterExternV3} from "rain.interpreter.interface/interface/IInterpreterExternV3.sol";
import {ISubParserV2} from "rain.interpreter.interface/interface/ISubParserV2.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {IDescribedByMetaV1} from "rain.metadata/interface/unstable/IDescribedByMetaV1.sol";

contract FlareFtsoWordsIERC165Test is Test {
    /// Test that ERC165 is implemented for the FlareFtsoWords contract.
    /// Need to check both `IInterpreterExternV3` and `ISubParserV2`.
    function testRainterpreterReferenceExternNPE2IERC165(bytes4 badInterfaceId) external {
        vm.assume(badInterfaceId != type(IERC165).interfaceId);
        vm.assume(badInterfaceId != type(IInterpreterExternV3).interfaceId);
        vm.assume(badInterfaceId != type(ISubParserV2).interfaceId);
        vm.assume(badInterfaceId != type(IDescribedByMetaV1).interfaceId);

        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        assertTrue(flareFtsoWords.supportsInterface(type(IERC165).interfaceId));
        assertTrue(flareFtsoWords.supportsInterface(type(IInterpreterExternV3).interfaceId));
        assertTrue(flareFtsoWords.supportsInterface(type(ISubParserV2).interfaceId));
        assertTrue(flareFtsoWords.supportsInterface(type(IDescribedByMetaV1).interfaceId));
        assertFalse(flareFtsoWords.supportsInterface(badInterfaceId));
    }
}
