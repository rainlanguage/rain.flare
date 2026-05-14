// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFork} from "../fork/LibFork.sol";
import {BLOCK_NUMBER} from "../src/lib/registry/LibFlareContractRegistry.t.sol";

import {IFlareContractRegistry} from "flare-smart-contracts/userInterfaces/IFlareContractRegistry.sol";
import {IFtsoRegistry} from "flare-smart-contracts/userInterfaces/IFtsoRegistry.sol";
import {IFtso} from "flare-smart-contracts/userInterfaces/IFtso.sol";
import {FtsoV2Interface} from "flare-smart-contracts-v2/userInterfaces/LTS/FtsoV2Interface.sol";
import {IFeeCalculator} from "flare-smart-contracts-v2/userInterfaces/IFeeCalculator.sol";

import {
    FLARE_CONTRACT_REGISTRY,
    FTSO_REGISTRY_NAME,
    FTSO_V2_LTS_NAME,
    FEE_CALCULATOR_NAME,
    LibFlareContractRegistry
} from "../../src/lib/registry/LibFlareContractRegistry.sol";
import {FLR_USD_FEED_ID, BTC_USD_FEED_ID} from "../../src/lib/lts/LibFtsoV2LTS.sol";

/// @title FlareInterfacesProdTest
/// @notice Exercises every method this repo calls on a vendored Flare
/// interface (src/vendor/) against the live Flare network at a pinned block.
/// If upstream Flare ever changes a method signature or removes a contract
/// from the canonical name registry, the corresponding test fails — catching
/// drift between our vendored copies and the on-chain ABI.
contract FlareInterfacesProdTest is Test {
    /// IFlareContractRegistry: name resolution is the entry point for every
    /// other interface we use.
    function testFlareContractRegistryGetContractAddressByName() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
        assertTrue(
            FLARE_CONTRACT_REGISTRY.getContractAddressByName(FTSO_REGISTRY_NAME) != address(0),
            "FtsoRegistry not registered"
        );
        assertTrue(
            FLARE_CONTRACT_REGISTRY.getContractAddressByName(FTSO_V2_LTS_NAME) != address(0), "FtsoV2 not registered"
        );
        assertTrue(
            FLARE_CONTRACT_REGISTRY.getContractAddressByName(FEE_CALCULATOR_NAME) != address(0),
            "FeeCalculator not registered"
        );
    }

    /// IFtsoRegistry.getFtsoBySymbol — used in LibFtsoCurrentPriceUsd to look
    /// up an FTSO by its symbol.
    function testFtsoRegistryGetFtsoBySymbol() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
        IFtsoRegistry registry = LibFlareContractRegistry.getFtsoRegistry();
        IFtso ftso = registry.getFtsoBySymbol("FLR");
        assertTrue(address(ftso) != address(0), "FLR FTSO not found");
    }

    /// IFtso.active and IFtso.getCurrentPriceWithDecimals — used in
    /// LibFtsoCurrentPriceUsd to read the FLR/USD price.
    function testFtsoActiveAndGetCurrentPriceWithDecimals() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
        IFtso ftso = LibFlareContractRegistry.getFtsoRegistry().getFtsoBySymbol("FLR");
        assertTrue(ftso.active(), "FLR FTSO not active");
        (uint256 price, uint256 timestamp, uint256 decimals) = ftso.getCurrentPriceWithDecimals();
        assertTrue(price > 0, "FLR price is zero");
        assertTrue(timestamp > 0, "FLR price timestamp is zero");
        assertTrue(decimals > 0 && decimals < 30, "FLR decimals out of plausible range");
    }

    /// IFtso.getCurrentPriceDetails — used in LibFtsoCurrentPricePair to
    /// guard against stale prices.
    function testFtsoGetCurrentPriceDetails() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
        IFtso ftso = LibFlareContractRegistry.getFtsoRegistry().getFtsoBySymbol("FLR");
        (uint256 price, uint256 timestamp,,,) = ftso.getCurrentPriceDetails();
        assertTrue(price > 0, "FLR price is zero");
        assertTrue(timestamp > 0, "FLR price timestamp is zero");
    }

    /// IFeeCalculator.calculateFeeByIds — used in LibFtsoV2LTS to compute
    /// the wei value needed for the FtsoV2 getFeedByIdInWei call.
    function testFeeCalculatorCalculateFeeByIds() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
        IFeeCalculator feeCalc = LibFlareContractRegistry.getFeeCalculator();
        bytes21[] memory feedIds = new bytes21[](1);
        feedIds[0] = FLR_USD_FEED_ID;
        uint256 fee = feeCalc.calculateFeeByIds(feedIds);
        // Fee is allowed to be zero on Flare but the call must not revert.
        assertTrue(fee < 1 ether, "fee is implausibly large");
    }

    /// FtsoV2Interface.getFeedByIdInWei — used in LibFtsoV2LTS for v2 LTS
    /// feed reads. The call is `payable`; we pay the fee returned by the
    /// FeeCalculator above.
    function testFtsoV2LTSGetFeedByIdInWei() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);
        FtsoV2Interface ftsoV2 = LibFlareContractRegistry.getFtsoV2LTS();
        IFeeCalculator feeCalc = LibFlareContractRegistry.getFeeCalculator();
        bytes21[] memory feedIds = new bytes21[](1);
        feedIds[0] = BTC_USD_FEED_ID;
        uint256 fee = feeCalc.calculateFeeByIds(feedIds);
        vm.deal(address(this), fee);
        (uint256 value, uint64 timestamp) = ftsoV2.getFeedByIdInWei{value: fee}(BTC_USD_FEED_ID);
        assertTrue(value > 0, "BTC feed value is zero");
        assertTrue(timestamp > 0, "BTC feed timestamp is zero");
    }
}
