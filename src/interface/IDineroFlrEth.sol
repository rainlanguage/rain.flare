// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

interface IDineroFlrEth {
    //slither-disable-next-line naming-convention
    function LSTPerToken() external view returns (uint256 ethAmount);

    function tokensPerLST() external view returns (uint256 tokenAmount);
}
