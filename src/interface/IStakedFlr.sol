// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

interface IStakedFlr {
    /// @notice Converts an amount of FLR into the equivalent number of sFLR shares at
    /// the current pool exchange rate. Both amounts are 18-decimal fixed point.
    /// @param flrAmount FLR amount (18 decimals) to convert.
    /// @return Number of sFLR shares (18 decimals) the FLR is worth now.
    function getSharesByPooledFlr(uint256 flrAmount) external view returns (uint256);

    /// @notice Inverse of getSharesByPooledFlr: converts sFLR shares back into pooled
    /// FLR at the current exchange rate. Both amounts are 18-decimal fixed point.
    /// @param shareAmount sFLR share amount (18 decimals) to convert.
    /// @return Pooled FLR amount (18 decimals) the shares are worth now.
    function getPooledFlrByShares(uint256 shareAmount) external view returns (uint256);

    /// @notice Stakes the FLR sent as msg.value, minting sFLR to the caller.
    /// @return Amount of sFLR shares minted to the caller.
    function submit() external payable returns (uint256);
}
