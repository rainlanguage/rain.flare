// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

interface IDineroFlrEth {
    //slither-disable-start naming-convention
    //forge-lint: disable-next-line(mixed-case-function)
    function LSTPerToken() external view returns (uint256 ethAmount);
    //slither-disable-end

    //forge-lint: disable-next-line(mixed-case-function)
    function tokensPerLST() external view returns (uint256 tokenAmount);
}
