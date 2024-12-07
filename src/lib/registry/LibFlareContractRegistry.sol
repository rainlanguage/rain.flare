// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {IFlareContractRegistry} from "flare-smart-contracts/userInterfaces/IFlareContractRegistry.sol";
import {IFtsoRegistry} from "flare-smart-contracts/userInterfaces/IFtsoRegistry.sol";
import {FtsoV2Interface} from "flare-smart-contracts-v2/userInterfaces/LTS/FtsoV2Interface.sol";
import {IFeeCalculator} from "flare-smart-contracts-v2/userInterfaces/IFeeCalculator.sol";

// The address of the Flare contract registry.
// This is the same and immutable across all Flare networks
// (mainnet, testnet, etc).
// https://docs.flare.network/dev/getting-started/contract-addresses/
IFlareContractRegistry constant FLARE_CONTRACT_REGISTRY =
    IFlareContractRegistry(0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019);

/// @dev Canonical name of the FTSO registry for lookups from the Flare contract
/// registry.
string constant FTSO_REGISTRY_NAME = "FtsoRegistry";

/// @dev Canonical name of the FTSO V2 LTS contract for lookups from the Flare
/// contract registry.
string constant FTSO_V2_LTS_NAME = "FtsoV2";

/// @dev Canonical name of the FeeCalculator contract for lookups from the Flare
/// contract registry.
string constant FEE_CALCULATOR_NAME = "FeeCalculator";

library LibFlareContractRegistry {
    /// Sugar for getting the FTSO registry address from the Flare contract
    /// registry.
    function getFtsoRegistry() internal view returns (IFtsoRegistry) {
        return IFtsoRegistry(FLARE_CONTRACT_REGISTRY.getContractAddressByName(FTSO_REGISTRY_NAME));
    }

    /// Sugar for getting the FTSO V2 LTS contract address from the Flare
    /// contract registry.
    function getFtsoV2LTS() internal view returns (FtsoV2Interface) {
        return FtsoV2Interface(FLARE_CONTRACT_REGISTRY.getContractAddressByName(FTSO_V2_LTS_NAME));
    }

    /// Sugar for getting the FeeCalculator contract address from the Flare
    /// contract registry.
    function getFeeCalculator() internal view returns (IFeeCalculator) {
        return IFeeCalculator(FLARE_CONTRACT_REGISTRY.getContractAddressByName(FEE_CALCULATOR_NAME));
    }
}
