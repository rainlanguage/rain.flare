// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

interface IStakedFlr {
    function getSharesByPooledFlr(uint256 flrAmount) external view returns (uint256);

    function getPooledFlrByShares(uint256 shareAmount) external view returns (uint256);

    function submit() external payable returns (uint256);
}
