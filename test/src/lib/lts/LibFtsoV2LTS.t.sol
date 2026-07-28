// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibFtsoV2LTS, ETH_USD_FEED_ID} from "src/lib/lts/LibFtsoV2LTS.sol";
import {BLOCK_NUMBER} from "test/fork/ForkConstants.sol";
import {LibFork} from "test/fork/LibFork.sol";
import {LibFlareContractRegistry} from "src/lib/registry/LibFlareContractRegistry.sol";
import {IFeeCalculator} from "../../../../src/vendor/flare-smart-contracts-v2/userInterfaces/IFeeCalculator.sol";
import {FtsoV2Interface} from "../../../../src/vendor/flare-smart-contracts-v2/userInterfaces/LTS/FtsoV2Interface.sol";
import {IGoverned, IGovernanceSettings} from "src/interface/IGoverned.sol";
import {IGovernedFeeCalculator} from "src/interface/IGovernedFeeCalculator.sol";
import {StalePrice} from "src/err/ErrFtso.sol";
import {FeedConsumer} from "test/lib/lts/FeedConsumer.sol";

contract LibFtsoV2LTSTest is Test {
    function testFtsoV2LTSGetFeed() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        uint256 feedValue = LibFtsoV2LTS.ftsoV2LTSGetFeed(ETH_USD_FEED_ID, 3600);
        assertEq(feedValue, 2522.575e18);
    }

    function testFtsoV2LTSGetFeedStale() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        FeedConsumer feedConsumer = new FeedConsumer();
        // The expected stale timestamp is the feed's timestamp as read at the
        // pinned fork block, so the assertion tracks BLOCK_NUMBER.
        FtsoV2Interface ftsoV2 = LibFlareContractRegistry.getFtsoV2LTS();
        (, uint64 feedTimestamp) = ftsoV2.getFeedByIdInWei(ETH_USD_FEED_ID);
        vm.warp(block.timestamp + 3601);
        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, uint256(feedTimestamp), 3600));
        feedConsumer.getFeedValue(ETH_USD_FEED_ID, 3600);
    }

    /// block.timestamp == feedTimestamp + timeout: the staleness check is strict `>`,
    /// so this must succeed (not stale).
    function testFtsoV2LTSGetFeedExactTimeoutNotStale() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        FeedConsumer feedConsumer = new FeedConsumer();
        vm.warp(1729795768 + 3600);
        uint256 value = feedConsumer.getFeedValue(ETH_USD_FEED_ID, 3600);
        assertGt(value, 0);
    }

    /// block.timestamp == feedTimestamp + timeout + 1: one second past the boundary
    /// must revert with StalePrice.
    function testFtsoV2LTSGetFeedJustStale() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        FeedConsumer feedConsumer = new FeedConsumer();
        vm.warp(1729795768 + 3600 + 1);
        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, 1729795768, 3600));
        feedConsumer.getFeedValue(ETH_USD_FEED_ID, 3600);
    }

    /// timeout == 0: any block.timestamp strictly after feedTimestamp is stale.
    function testFtsoV2LTSGetFeedTimeoutZeroStale() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        FeedConsumer feedConsumer = new FeedConsumer();
        vm.warp(1729795768 + 1);
        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, 1729795768, 0));
        feedConsumer.getFeedValue(ETH_USD_FEED_ID, 0);
    }

    /// timeout == 0 at exactly feedTimestamp: not stale (0 > 0 is false).
    function testFtsoV2LTSGetFeedTimeoutZeroExactNotStale() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        FeedConsumer feedConsumer = new FeedConsumer();
        vm.warp(1729795768);
        uint256 value = feedConsumer.getFeedValue(ETH_USD_FEED_ID, 0);
        assertGt(value, 0);
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
        // OutOfFunds is an EVM error with no Solidity revert data.
        vm.expectRevert(new bytes(0));
        feedConsumer.getFeedValue(ETH_USD_FEED_ID, 3600);

        vm.expectRevert(new bytes(0));
        feedConsumer.getFeedValue{value: alice.balance}(ETH_USD_FEED_ID, 3600);

        vm.deal(alice, fee);
        assertEq(alice.balance, fee);
        uint256 feedValue = feedConsumer.getFeedValue{value: alice.balance}(ETH_USD_FEED_ID, 3600);
        assertEq(feedValue, 2522.575e18);
        assertEq(alice.balance, 0);

        // #56 — overpayment: surplus is stranded in the consumer (documents current behavior;
        // replace with refund assertion when a refund mechanism is added).
        vm.deal(alice, uint256(fee) + 1 ether);
        uint256 overpaidValue = feedConsumer.getFeedValue{value: alice.balance}(ETH_USD_FEED_ID, 3600);
        assertEq(overpaidValue, 2522.575e18);
        assertEq(address(feedConsumer).balance, 1 ether);
        assertEq(alice.balance, 0);
    }
}
