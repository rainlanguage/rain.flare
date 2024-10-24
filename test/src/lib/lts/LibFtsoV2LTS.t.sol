// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibFtsoV2LTS, ETH_USD_FEED_ID} from "src/lib/lts/LibFtsoV2LTS.sol";
import {BLOCK_NUMBER} from "../registry/LibFlareContractRegistry.t.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {FtsoV2Interface} from "flare-smart-contracts-v2/userInterfaces/LTS/FtsoV2Interface.sol";
import {LibFlareContractRegistry} from "src/lib/registry/LibFlareContractRegistry.sol";
import {IFeeCalculator} from "flare-smart-contracts-v2/userInterfaces/IFeeCalculator.sol";
import {IGoverned, IGovernanceSettings} from "src/interface/IGoverned.sol";
import {IGovernedFeeCalculator} from "src/interface/IGovernedFeeCalculator.sol";

contract LibFtsoV2LTSTest is Test {
    function testFtsoV2LTSGetFeed() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        uint256 feedValue = LibFtsoV2LTS.ftsoV2LTSGetFeed(ETH_USD_FEED_ID, 3600);
        assertEq(feedValue, 2552.635e18);
    }

    function testFtsoV2LTSGetFeedPaid() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        FtsoV2Interface ftsoRegistry = LibFlareContractRegistry.getFtsoV2LTS();
        IFeeCalculator feeCalculator = LibFlareContractRegistry.getFeeCalculator();

        address gov = IGoverned(address(feeCalculator)).governance();
        IGovernanceSettings govSettings = IGoverned(address(feeCalculator)).governanceSettings();

        address[] memory executors = govSettings.getExecutors();
        uint256 timelock = govSettings.getTimelock();

        vm.prank(gov);
        IGovernedFeeCalculator(address(feeCalculator)).setDefaultFee(5e18);

        vm.warp(block.timestamp + timelock + 1);

        vm.prank(executors[0]);
        IGoverned(address(feeCalculator)).executeGovernanceCall(bytes4(0xc93a6c84));

        uint256 feedValue = LibFtsoV2LTS.ftsoV2LTSGetFeed(ETH_USD_FEED_ID, 3600);
        assertEq(feedValue, 2552.635e18);
    }
}
