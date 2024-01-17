// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Test} from "forge-std/Test.sol";
import {Operand} from "rain.interpreter/interface/unstable/IInterpreterV2.sol";
import {
    LibOpFtsoCurrentPriceUsd,
    IFtso,
    IFtsoRegistry,
    InactiveFtso,
    PriceNotFinalized
} from "src/lib/op/LibOpFtsoCurrentPriceUsd.sol";
import {
    LibFlareContractRegistry,
    FLARE_CONTRACT_REGISTRY,
    FTSO_REGISTRY_NAME,
    IFlareContractRegistry
} from "src/lib/registry/LibFlareContractRegistry.sol";

contract LibOpFtsoCurrentPriceUsdTest is Test {
    struct PriceDetails {
        uint256 price;
        uint256 priceTimestamp;
        uint8 priceFinalizationType;
        uint256 lastPriceEpochFinalizationTimestamp;
        uint8 lastPriceEpochFinalizationType;
    }

    /// Seems to be a bug in foundry where it can't create enums in structs in
    /// the fuzzer without erroring.
    function conformPriceDetails(PriceDetails memory priceDetails) internal {
        priceDetails.priceFinalizationType = uint8(
            bound(
                uint256(priceDetails.priceFinalizationType),
                uint256(type(IFtso.PriceFinalizationType).min),
                uint256(type(IFtso.PriceFinalizationType).max)
            )
        );
        priceDetails.lastPriceEpochFinalizationType = uint8(
            bound(
                uint256(priceDetails.lastPriceEpochFinalizationType),
                uint256(type(IFtso.PriceFinalizationType).min),
                uint256(type(IFtso.PriceFinalizationType).max)
            )
        );
    }

    function testIntegrity(Operand operand, uint256 inputs, uint256 outputs) external {
        (uint256 calculatedInputs, uint256 calculatedOutputs) =
            LibOpFtsoCurrentPriceUsd.integrity(operand, inputs, outputs);
        assertEq(calculatedInputs, 2);
        assertEq(calculatedOutputs, 1);
    }

    function externalRun(Operand operand, uint256[] memory inputs) external view returns (uint256[] memory) {
        return LibOpFtsoCurrentPriceUsd.run(operand, inputs);
    }

    function testRunFtsoFinalizationOutOfBounds(Operand operand, uint256[] memory inputs, PriceDetails memory priceDetails) external {
        // Make the finalisation type out of bounds.
        priceDetails.priceFinalizationType = uint8(
            bound(
                uint256(priceDetails.priceFinalizationType),
                uint256(type(IFtso.PriceFinalizationType).max),
                uint256(type(uint8).max)
            )
        );
        // Keep the last epoch finalisation type in bounds.
        priceDetails.lastPriceEpochFinalizationType = uint8(
            bound(
                uint256(priceDetails.lastPriceEpochFinalizationType),
                uint256(type(IFtso.PriceFinalizationType).min),
                uint256(type(IFtso.PriceFinalizationType).max)
            )
        );
        address ftsoRegistry = address(0x1000000);
        vm.label(ftsoRegistry, "ftsoRegistry");
        address ftso = address(0x2000000);
        vm.label(ftso, "ftso");
        vm.etch(address(FLARE_CONTRACT_REGISTRY), hex"fe");
        vm.mockCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(IFlareContractRegistry.getContractAddressByName.selector, FTSO_REGISTRY_NAME),
            abi.encode(ftsoRegistry)
        );
        vm.etch(ftsoRegistry, hex"fe");
        vm.mockCall(ftsoRegistry, abi.encodeWithSelector(IFtsoRegistry.getFtsoBySymbol.selector), abi.encode(ftso));
        vm.etch(ftso, hex"fe");
        vm.mockCall(ftso, abi.encodeWithSelector(IFtso.active.selector), abi.encode(true));
        vm.mockCall(
            ftso,
            abi.encodeWithSelector(IFtso.getCurrentPriceDetails.selector),
            abi.encode(
                priceDetails.price,
                priceDetails.priceTimestamp,
                IFtso.PriceFinalizationType(priceDetails.priceFinalizationType),
                priceDetails.lastPriceEpochFinalizationTimestamp,
                IFtso.PriceFinalizationType(priceDetails.lastPriceEpochFinalizationType)
            )
        );
        vm.expectRevert();
        this.externalRun(operand, inputs);
    }

    /// Anything other than WEIGHTED_MEDIAN should revert as it means the price
    /// is either not final or oracle participation was too low.
    function testRunFtsoNotFinal(Operand operand, uint256[] memory inputs, PriceDetails memory priceDetails) external {
        conformPriceDetails(priceDetails);
        vm.assume(priceDetails.priceFinalizationType != uint8(IFtso.PriceFinalizationType.WEIGHTED_MEDIAN));
        address ftsoRegistry = address(0x1000000);
        vm.label(ftsoRegistry, "ftsoRegistry");
        address ftso = address(0x2000000);
        vm.label(ftso, "ftso");
        vm.etch(address(FLARE_CONTRACT_REGISTRY), hex"fe");
        vm.mockCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(IFlareContractRegistry.getContractAddressByName.selector, FTSO_REGISTRY_NAME),
            abi.encode(ftsoRegistry)
        );
        vm.etch(ftsoRegistry, hex"fe");
        vm.mockCall(ftsoRegistry, abi.encodeWithSelector(IFtsoRegistry.getFtsoBySymbol.selector), abi.encode(ftso));
        vm.etch(ftso, hex"fe");
        vm.mockCall(ftso, abi.encodeWithSelector(IFtso.active.selector), abi.encode(true));
        vm.mockCall(
            ftso,
            abi.encodeWithSelector(IFtso.getCurrentPriceDetails.selector),
            abi.encode(
                priceDetails.price,
                priceDetails.priceTimestamp,
                IFtso.PriceFinalizationType(priceDetails.priceFinalizationType),
                priceDetails.lastPriceEpochFinalizationTimestamp,
                IFtso.PriceFinalizationType(priceDetails.lastPriceEpochFinalizationType)
            )
        );
        vm.expectRevert(abi.encodeWithSelector(PriceNotFinalized.selector, priceDetails.priceFinalizationType));
        this.externalRun(operand, inputs);
    }

    function testRunFtsoNotActive(Operand operand, uint256[] memory inputs) external {
        address ftsoRegistry = address(0x1000000);
        address ftso = address(0x2000000);
        vm.etch(address(FLARE_CONTRACT_REGISTRY), hex"fe");
        vm.mockCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(IFlareContractRegistry.getContractAddressByName.selector, FTSO_REGISTRY_NAME),
            abi.encode(ftso)
        );
        vm.etch(ftsoRegistry, hex"fe");
        vm.mockCall(ftso, abi.encodeWithSelector(IFtsoRegistry.getFtsoBySymbol.selector), abi.encode(ftso));
        vm.etch(ftso, hex"fe");
        vm.mockCall(ftso, abi.encodeWithSelector(IFtso.active.selector), abi.encode(false));
        vm.expectRevert(abi.encodeWithSelector(InactiveFtso.selector));
        this.externalRun(operand, inputs);
    }

    function testRunNoFtso(Operand operand, uint256[] memory inputs) external {
        address ftsoRegistry = address(0x1000000);
        address ftso = address(0x2000000);
        vm.etch(address(FLARE_CONTRACT_REGISTRY), hex"fe");
        vm.mockCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(IFlareContractRegistry.getContractAddressByName.selector, FTSO_REGISTRY_NAME),
            abi.encode(ftso)
        );
        vm.etch(ftsoRegistry, hex"fe");
        vm.mockCall(ftso, abi.encodeWithSelector(IFtsoRegistry.getFtsoBySymbol.selector), abi.encode(ftso));
        vm.etch(ftso, hex"fe");
        vm.expectRevert();
        this.externalRun(operand, inputs);
    }

    function testRunRegistryNoFtsoRegistry(Operand operand, uint256[] memory inputs) external {
        vm.etch(address(FLARE_CONTRACT_REGISTRY), hex"fe");
        vm.mockCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(IFlareContractRegistry.getContractAddressByName.selector, FTSO_REGISTRY_NAME),
            abi.encode(address(0))
        );
        vm.expectRevert();
        this.externalRun(operand, inputs);
    }

    function testRunNoRegistry(Operand operand, uint256[] memory inputs) external {
        // This is going to revert because we haven't set up a registry.
        vm.expectRevert();
        this.externalRun(operand, inputs);
    }
}
