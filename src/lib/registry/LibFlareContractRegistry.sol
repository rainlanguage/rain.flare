// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.19;

import {FtsoV2Interface} from "../../vendor/flare-smart-contracts-v2/userInterfaces/LTS/FtsoV2Interface.sol";
import {IFeeCalculator} from "../../vendor/flare-smart-contracts-v2/userInterfaces/IFeeCalculator.sol";
import {IFtsoRegistry} from "../../vendor/flare-smart-contracts/userInterfaces/IFtsoRegistry.sol";
import {IFlareContractRegistry} from "../../vendor/flare-smart-contracts/userInterfaces/IFlareContractRegistry.sol";
//forge-lint: disable-next-line(unused-import)
import {IFtso} from "../../vendor/flare-smart-contracts/userInterfaces/IFtso.sol";

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

/// @notice Thrown when a name lookup in the Flare contract registry returns
/// address(0). IFlareContractRegistry documents address(0) as the not-found
/// sentinel; propagating a zero-typed contract handle silently would cause
/// every subsequent call to revert with a confusing low-level error.
/// @param name The registry name that resolved to address(0).
error ContractNotRegistered(string name);

library LibFlareContractRegistry {
    /// Sugar for getting the FTSO registry address from the Flare contract
    /// registry. Reverts with ContractNotRegistered if the name is not found.
    function getFtsoRegistry() internal view returns (IFtsoRegistry) {
        address addr = FLARE_CONTRACT_REGISTRY.getContractAddressByName(FTSO_REGISTRY_NAME);
        if (addr == address(0)) revert ContractNotRegistered(FTSO_REGISTRY_NAME);
        return IFtsoRegistry(addr);
    }

    /// Sugar for getting the FTSO V2 LTS contract address from the Flare
    /// contract registry. Reverts with ContractNotRegistered if the name is not
    /// found.
    //forge-lint: disable-next-line(mixed-case-function)
    function getFtsoV2LTS() internal view returns (FtsoV2Interface) {
        address addr = FLARE_CONTRACT_REGISTRY.getContractAddressByName(FTSO_V2_LTS_NAME);
        if (addr == address(0)) revert ContractNotRegistered(FTSO_V2_LTS_NAME);
        return FtsoV2Interface(addr);
    }

    /// Sugar for getting the FeeCalculator contract address from the Flare
    /// contract registry. Reverts with ContractNotRegistered if the name is not
    /// found.
    function getFeeCalculator() internal view returns (IFeeCalculator) {
        address addr = FLARE_CONTRACT_REGISTRY.getContractAddressByName(FEE_CALCULATOR_NAME);
        if (addr == address(0)) revert ContractNotRegistered(FEE_CALCULATOR_NAME);
        return IFeeCalculator(addr);
    }
}
