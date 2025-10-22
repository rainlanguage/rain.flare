// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {IInterpreterExternV4} from "rain.interpreter.interface/interface/unstable/IInterpreterExternV4.sol";
import {ISubParserV4} from "rain.interpreter.interface/interface/unstable/ISubParserV4.sol";
import {FlareFtsoWords} from "src/concrete/FlareFtsoWords.sol";
import {IDescribedByMetaV1} from "rain.metadata/interface/IDescribedByMetaV1.sol";
import {IIntegrityToolingV1} from "rain.sol.codegen/interface/IIntegrityToolingV1.sol";
import {IOpcodeToolingV1} from "rain.sol.codegen/interface/IOpcodeToolingV1.sol";
import {IParserToolingV1} from "rain.sol.codegen/interface/IParserToolingV1.sol";

contract FlareFtsoWordsIERC165Test is Test {
    /// Test that ERC165 is implemented for the FlareFtsoWords contract.
    /// Need to check both `IInterpreterExternV3` and `ISubParserV2`.
    function testRainterpreterReferenceExternNPE2IERC165(bytes4 badInterfaceId) external {
        vm.assume(badInterfaceId != type(IERC165).interfaceId);
        vm.assume(badInterfaceId != type(IInterpreterExternV4).interfaceId);
        vm.assume(badInterfaceId != type(ISubParserV4).interfaceId);
        vm.assume(badInterfaceId != type(IDescribedByMetaV1).interfaceId);
        vm.assume(badInterfaceId != type(IIntegrityToolingV1).interfaceId);
        vm.assume(badInterfaceId != type(IOpcodeToolingV1).interfaceId);
        vm.assume(badInterfaceId != type(IParserToolingV1).interfaceId);

        FlareFtsoWords flareFtsoWords = new FlareFtsoWords();
        assertTrue(flareFtsoWords.supportsInterface(type(IERC165).interfaceId));
        assertTrue(flareFtsoWords.supportsInterface(type(IInterpreterExternV4).interfaceId));
        assertTrue(flareFtsoWords.supportsInterface(type(ISubParserV4).interfaceId));
        assertTrue(flareFtsoWords.supportsInterface(type(IDescribedByMetaV1).interfaceId));
        assertTrue(flareFtsoWords.supportsInterface(type(IIntegrityToolingV1).interfaceId));
        assertTrue(flareFtsoWords.supportsInterface(type(IOpcodeToolingV1).interfaceId));
        assertTrue(flareFtsoWords.supportsInterface(type(IParserToolingV1).interfaceId));
        assertFalse(flareFtsoWords.supportsInterface(badInterfaceId));
    }
}
