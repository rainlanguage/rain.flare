// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {IDineroFlrEth} from "../../interface/IDineroFlrEth.sol";

IDineroFlrEth constant FLRETH_CONTRACT = IDineroFlrEth(address(0x26A1faB310bd080542DC864647d05985360B16A5));

library LibDineroFlrEth {
    /// Fixed 18 decimal place ratio of ETH per FLRETH.
    /// For each 1e18 FLRETH, this is how many ETH are deposited.
    /// Calls IDineroFlrEth.LSTPerToken(). In the upstream Dinero
    /// WrappedLiquidStakedToken contract (dinero-protocol/pirex-eth-contracts
    /// src/layer2/WrappedLiquidStakedToken.sol, the verified implementation
    /// behind the FLRETH_CONTRACT proxy), "Token" is the wrapped FLRETH share
    /// and "LST" is the underlying ETH-denominated LiquidStakingToken, so
    /// LSTPerToken() is lst.convertToAssets(1e18): underlying ETH per 1e18
    /// FLRETH. FLRETH accrues staking rewards, so on chain this value starts
    /// at 1e18 and grows; the fork test pins that >= 1e18 direction.
    /// This value is the reciprocal of getFLRETHPerETH18().
    //forge-lint: disable-next-line(mixed-case-function)
    function getETHPerFLRETH18() internal view returns (uint256) {
        return FLRETH_CONTRACT.LSTPerToken();
    }

    /// Fixed 18 decimal place ratio of FLRETH per ETH.
    /// For each 1e18 ETH, this is how many FLRETH are minted.
    /// Calls IDineroFlrEth.tokensPerLST(). In the upstream Dinero
    /// WrappedLiquidStakedToken contract, tokensPerLST() is
    /// lst.convertToShares(1e18): wrapped FLRETH shares per 1e18 underlying
    /// ETH. As staking rewards accrue this value falls below 1e18; the fork
    /// test pins that <= 1e18 direction.
    /// This value is the reciprocal of getETHPerFLRETH18().
    //forge-lint: disable-next-line(mixed-case-function)
    function getFLRETHPerETH18() internal view returns (uint256) {
        return FLRETH_CONTRACT.tokensPerLST();
    }
}
