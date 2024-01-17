// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Test} from "forge-std/Test.sol";
import {Operand} from "rain.interpreter/interface/unstable/IInterpreterV2.sol";
import {
    LibOpFtsoCurrentPriceUsd,
    IFtso,
    IFtsoRegistry,
    InactiveFtso,
    PriceNotFinalized,
    StalePrice
} from "src/lib/op/LibOpFtsoCurrentPriceUsd.sol";
import {
    LibFlareContractRegistry,
    FLARE_CONTRACT_REGISTRY,
    FTSO_REGISTRY_NAME,
    IFlareContractRegistry
} from "src/lib/registry/LibFlareContractRegistry.sol";
import {LibFixedPointDecimalScale} from "rain.math.fixedpoint/lib/LibFixedPointDecimalScale.sol";

contract LibOpFtsoCurrentPriceUsdTest is Test {
    struct PriceDetails {
        uint256 price;
        uint256 priceTimestamp;
        uint8 priceFinalizationType;
        uint256 lastPriceEpochFinalizationTimestamp;
        uint8 lastPriceEpochFinalizationType;
    }

    struct CurrentPrice {
        uint256 price;
        uint256 timestamp;
        uint256 decimals;
    }

    address constant FTSO = address(0x1000000);
    address constant FTSO_REGISTRY = address(0x2000000);

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

    function mockRegistry() internal {
        vm.etch(address(FLARE_CONTRACT_REGISTRY), hex"fe");
        vm.etch(FTSO_REGISTRY, hex"fe");
        vm.etch(FTSO, hex"fe");

        vm.label(address(FLARE_CONTRACT_REGISTRY), "flareContractRegistry");
        vm.label(FTSO_REGISTRY, "ftsoRegistry");
        vm.label(FTSO, "ftso");

        vm.mockCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(IFlareContractRegistry.getContractAddressByName.selector, FTSO_REGISTRY_NAME),
            abi.encode(FTSO_REGISTRY)
        );
        vm.mockCall(FTSO_REGISTRY, abi.encodeWithSelector(IFtsoRegistry.getFtsoBySymbol.selector), abi.encode(FTSO));
    }

    function activateFtso() internal {
        vm.mockCall(FTSO, abi.encodeWithSelector(IFtso.active.selector), abi.encode(true));
    }

    function mockPriceDetails(PriceDetails memory priceDetails) internal {
        vm.mockCall(
            FTSO,
            abi.encodeWithSelector(IFtso.getCurrentPriceDetails.selector),
            abi.encode(
                priceDetails.price,
                priceDetails.priceTimestamp,
                IFtso.PriceFinalizationType(priceDetails.priceFinalizationType),
                priceDetails.lastPriceEpochFinalizationTimestamp,
                IFtso.PriceFinalizationType(priceDetails.lastPriceEpochFinalizationType)
            )
        );
    }

    function finalizePrice(PriceDetails memory priceDetails) internal {
        priceDetails.priceFinalizationType = uint8(IFtso.PriceFinalizationType.WEIGHTED_MEDIAN);
    }

    function mockPrice(CurrentPrice memory currentPrice) internal {
        vm.mockCall(
            FTSO,
            abi.encodeWithSelector(IFtso.getCurrentPriceWithDecimals.selector),
            abi.encode(currentPrice.price, currentPrice.timestamp, currentPrice.decimals)
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

    function testRunHappy(Operand operand, uint256 symbol, uint256 timeout, uint256 currentTime, PriceDetails memory priceDetails, CurrentPrice memory currentPrice) external {
        // timeout = bound(timeout, 1, type(uint256).max);
        currentPrice.timestamp = bound(currentPrice.timestamp, 0, type(uint256).max - timeout);
        currentTime = bound(currentTime, currentPrice.timestamp, currentPrice.timestamp + timeout);
        vm.warp(currentTime);

        conformPriceDetails(priceDetails);
        finalizePrice(priceDetails);

        mockRegistry();
        activateFtso();
        mockPriceDetails(priceDetails);
        mockPrice(currentPrice);

        uint256[] memory inputs = new uint256[](2);
        inputs[0] = symbol;
        inputs[1] = timeout;
        uint256[] memory outputs = this.externalRun(operand, inputs);
        assertEq(outputs.length, 1);
        assertEq(outputs[0], LibFixedPointDecimalScale.scale18(currentPrice.price, currentPrice.decimals, 0));
    }

    /// If the timestamp is too old, the price is stale.
    function testRunStale(Operand operand, uint256 symbol, uint256 timeout, uint256 currentTime, PriceDetails memory priceDetails, CurrentPrice memory currentPrice) external {
        timeout = bound(timeout, 0, type(uint256).max - 2);
        currentPrice.timestamp = bound(currentPrice.timestamp, 0, type(uint256).max - timeout - 1);
        currentTime = bound(currentTime, currentPrice.timestamp + timeout + 1, type(uint256).max);
        vm.warp(currentTime);

        conformPriceDetails(priceDetails);
        finalizePrice(priceDetails);

        mockRegistry();
        activateFtso();
        mockPriceDetails(priceDetails);
        mockPrice(currentPrice);

        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, currentPrice.timestamp, timeout));
        uint256[] memory inputs = new uint256[](2);
        inputs[0] = symbol;
        inputs[1] = timeout;
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
