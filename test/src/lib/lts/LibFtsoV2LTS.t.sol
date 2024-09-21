// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibFtsoV2LTS, ETH_USD_FEED_ID} from "src/lib/lts/LibFtsoV2LTS.sol";
import {BLOCK_NUMBER} from "../registry/LibFlareContractRegistry.t.sol";
import {LibFork} from "test/fork/LibFork.sol";

contract LibFtsoV2LTSTest is Test {
    function testFtsoV2LTSGetFeed() external {
        vm.createSelectFork(LibFork.rpcUrlFlare(vm), BLOCK_NUMBER);

        uint256 feedValue = LibFtsoV2LTS.ftsoV2LTSGetFeed(ETH_USD_FEED_ID, 3600);
        assertEq(feedValue, 2552.635e18);
    }
}
