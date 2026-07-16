// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibFtsoV2LTS} from "src/lib/lts/LibFtsoV2LTS.sol";
import {Float} from "rain-math-float-0.1.1/src/lib/LibDecimalFloat.sol";

contract FeedConsumer {
    function getFeedValue(bytes21 feedId, uint256 timeout) external payable returns (Float) {
        return LibFtsoV2LTS.ftsoV2LTSGetFeed(feedId, timeout);
    }
}
