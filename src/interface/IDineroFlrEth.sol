// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

interface IDineroFlrEth {
    //slither-disable-start naming-convention
    /// @notice Amount of underlying LST (ETH) backing one whole flrETH token.
    /// @return ethAmount ETH per 1e18 flrETH, as an 18-decimal fixed point value.
    //forge-lint: disable-next-line(mixed-case-function)
    function LSTPerToken() external view returns (uint256 ethAmount);
    //slither-disable-end

    /// @notice Amount of flrETH minted per one whole unit of underlying LST (ETH).
    /// @return tokenAmount flrETH per 1e18 ETH, as an 18-decimal fixed point value.
    //forge-lint: disable-next-line(mixed-case-function)
    function tokensPerLST() external view returns (uint256 tokenAmount);
}
