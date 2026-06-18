// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

interface IStakedFlr {
    /// @dev Returns the number of sFLR shares that correspond to `flrAmount`
    /// of pooled FLR at the current exchange rate. 18-decimal fixed point.
    /// @param flrAmount The amount of FLR to convert, in wei.
    /// @return The equivalent number of sFLR shares, scaled to 18 decimals.
    function getSharesByPooledFlr(uint256 flrAmount) external view returns (uint256);

    /// @dev Returns the amount of pooled FLR that corresponds to `shareAmount`
    /// of sFLR shares at the current exchange rate. 18-decimal fixed point.
    /// @param shareAmount The number of sFLR shares to convert.
    /// @return The equivalent pooled FLR amount, in wei.
    function getPooledFlrByShares(uint256 shareAmount) external view returns (uint256);

    /// @dev Deposits native FLR (via msg.value) into the sFLR pool and mints
    /// the corresponding sFLR shares to msg.sender.
    /// @return The number of sFLR shares minted to the caller.
    function submit() external payable returns (uint256);
}
