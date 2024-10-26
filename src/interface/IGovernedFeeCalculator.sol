// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.25;

interface IGovernedFeeCalculator {
    function setDefaultFee(uint256 fee) external;

    function setFeedsFees(bytes21[] memory feeds, uint256[] memory fees) external;
}
