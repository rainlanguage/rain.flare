// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Test} from "forge-std/Test.sol";
import {IFtso} from "flare-smart-contracts/userInterfaces/IFtso.sol";
import {
    IFtsoRegistry,
    LibFlareContractRegistry,
    FLARE_CONTRACT_REGISTRY,
    FTSO_REGISTRY_NAME,
    IFlareContractRegistry
} from "src/lib/registry/LibFlareContractRegistry.sol";
import {Operand} from "rain.interpreter/interface/unstable/IInterpreterV2.sol";

abstract contract FtsoTest is Test {
    address constant FTSO = address(0x1000000);
    address constant FTSO_REGISTRY = address(0x2000000);

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

    function externalRun(Operand, uint256[] memory) external view virtual returns (uint256[] memory);

    /// Seems to be a bug in foundry where it can't create enums in structs in
    /// the fuzzer without erroring.
    function conformPriceDetails(PriceDetails memory priceDetails, CurrentPrice memory currentPrice) internal pure {
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
        priceDetails.price = currentPrice.price;
        priceDetails.priceTimestamp = currentPrice.timestamp;
    }

    function mockRegistry(string memory symbol) internal {
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
        vm.expectCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(IFlareContractRegistry.getContractAddressByName.selector, FTSO_REGISTRY_NAME),
            1
        );
        vm.mockCall(
            FTSO_REGISTRY, abi.encodeWithSelector(IFtsoRegistry.getFtsoBySymbol.selector, symbol), abi.encode(FTSO)
        );
        vm.expectCall(FTSO_REGISTRY, abi.encodeWithSelector(IFtsoRegistry.getFtsoBySymbol.selector, symbol), 1);
    }

    function activateFtso() internal {
        vm.mockCall(FTSO, abi.encodeWithSelector(IFtso.active.selector), abi.encode(true));
        vm.expectCall(FTSO, abi.encodeWithSelector(IFtso.active.selector), 1);
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
        vm.expectCall(FTSO, abi.encodeWithSelector(IFtso.getCurrentPriceDetails.selector), 1);
    }

    function finalizePrice(PriceDetails memory priceDetails) internal pure {
        priceDetails.priceFinalizationType = uint8(IFtso.PriceFinalizationType.WEIGHTED_MEDIAN);
    }

    function mockPrice(CurrentPrice memory currentPrice) internal {
        vm.mockCall(
            FTSO,
            abi.encodeWithSelector(IFtso.getCurrentPriceWithDecimals.selector),
            abi.encode(currentPrice.price, currentPrice.timestamp, currentPrice.decimals)
        );
    }

    function testRunNoRegistry(Operand operand, uint256[] memory inputs) external {
        // This is going to revert because we haven't set up a registry.
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

    function testRunInvalidFtso(Operand operand, uint256[] memory inputs) external {
        vm.etch(address(FLARE_CONTRACT_REGISTRY), hex"fe");
        vm.mockCall(
            address(FLARE_CONTRACT_REGISTRY),
            abi.encodeWithSelector(IFlareContractRegistry.getContractAddressByName.selector, FTSO_REGISTRY_NAME),
            abi.encode(FTSO)
        );
        vm.etch(FTSO_REGISTRY, hex"fe");
        vm.mockCall(FTSO_REGISTRY, abi.encodeWithSelector(IFtsoRegistry.getFtsoBySymbol.selector), abi.encode(FTSO));
        vm.etch(FTSO, hex"fe");
        vm.expectRevert();
        this.externalRun(operand, inputs);
    }
}
