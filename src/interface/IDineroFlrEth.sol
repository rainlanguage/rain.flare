// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

interface IDineroFlrEth {
    /// @dev Returns the number of flrETH (LST) tokens a holder receives per
    /// native FLR token, expressed as an 18-decimal fixed-point ratio
    /// (i.e. 1e18 means 1:1).
    //slither-disable-start naming-convention
    //forge-lint: disable-next-line(mixed-case-function)
    function LSTPerToken() external view returns (uint256 lstsPerToken);
    //slither-disable-end

    /// @dev Returns the number of native FLR tokens redeemable per flrETH
    /// (LST) token, expressed as an 18-decimal fixed-point ratio
    /// (i.e. 1e18 means 1:1).
    //forge-lint: disable-next-line(mixed-case-function)
    function tokensPerLST() external view returns (uint256 tokensPerLst);
}
