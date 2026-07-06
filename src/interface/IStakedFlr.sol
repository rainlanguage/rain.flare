// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

interface IStakedFlr {
    /// @notice Returns the number of sFLR shares equivalent to the given amount
    /// of pooled FLR. This is the sFLR-per-FLR direction of the exchange rate.
    /// @dev Both input and output are 18-decimal fixed-point values.
    /// Rounds down (floor), favouring the protocol.
    /// @param flrAmount Amount of pooled FLR in 1e18 fixed-point.
    /// @return Equivalent sFLR shares in 1e18 fixed-point.
    function getSharesByPooledFlr(uint256 flrAmount) external view returns (uint256);
}
