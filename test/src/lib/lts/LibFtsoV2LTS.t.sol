// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
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
import {StalePrice} from "src/err/ErrFtso.sol";

contract FeedConsumer {
    function getFeedValue(bytes21 feedId, uint256 timeout) external payable returns (uint256) {
        return LibFtsoV2LTS.ftsoV2LTSGetFeed(feedId, timeout);
    }
}

contract LibFtsoV2LTSTest is Test {
    function testFtsoV2LTSGetFeed() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        uint256 feedValue = LibFtsoV2LTS.ftsoV2LTSGetFeed(ETH_USD_FEED_ID, 3600);
        assertEq(feedValue, 2522.575e18);
    }

    function testFtsoV2LTSGetFeedStale() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        FeedConsumer feedConsumer = new FeedConsumer();
        vm.warp(block.timestamp + 3601);
        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, 1729795768, 3600));
        feedConsumer.getFeedValue(ETH_USD_FEED_ID, 3600);
    }

    /// forge-config: default.fuzz.runs = 1
    function testFtsoV2LTSGetFeedPaid(uint128 fee) external {
        vm.assume(fee > 0);
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        FeedConsumer feedConsumer = new FeedConsumer();

        IFeeCalculator feeCalculator = LibFlareContractRegistry.getFeeCalculator();

        address gov = IGoverned(address(feeCalculator)).governance();
        IGovernanceSettings govSettings = IGoverned(address(feeCalculator)).governanceSettings();

        address[] memory executors = govSettings.getExecutors();
        uint256 timelock = govSettings.getTimelock();

        vm.prank(gov);

        bytes21[] memory feeds = new bytes21[](1);
        feeds[0] = bytes21(ETH_USD_FEED_ID);
        uint256[] memory fees = new uint256[](1);
        fees[0] = fee;
        bytes4 setFeedsFeesSelector = bytes4(0x755fcecd);
        IGovernedFeeCalculator(address(feeCalculator)).setFeedsFees(feeds, fees);

        vm.warp(block.timestamp + timelock);

        vm.prank(executors[0]);
        IGoverned(address(feeCalculator)).executeGovernanceCall(setFeedsFeesSelector);

        address alice = address(uint160(uint256(keccak256("alice"))));
        assertEq(alice.balance, 0);
        vm.deal(alice, fee - 1);
        assertEq(alice.balance, fee - 1);

        vm.startPrank(alice);
        vm.expectRevert();
        feedConsumer.getFeedValue(ETH_USD_FEED_ID, 3600);

        vm.expectRevert();
        feedConsumer.getFeedValue{value: alice.balance}(ETH_USD_FEED_ID, 3600);

        vm.deal(alice, fee);
        assertEq(alice.balance, fee);
        uint256 feedValue = feedConsumer.getFeedValue{value: alice.balance}(ETH_USD_FEED_ID, 3600);
        assertEq(feedValue, 2522.575e18);
        assertEq(alice.balance, 0);
    }
}
