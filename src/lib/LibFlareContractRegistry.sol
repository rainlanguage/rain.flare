// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {IFlareContractRegistry} from "flare-smart-contracts/userInterfaces/IFlareContractRegistry.sol";
import {IFtsoRegistry} from "flare-smart-contracts/userInterfaces/IFtsoRegistry.sol";

library LibFlareContractRegistry {
    /// The address of the Flare contract registry.
    /// This is the same and immutable across all Flare networks
    /// (mainnet, testnet, etc).
    /// https://docs.flare.network/dev/getting-started/contract-addresses/
    IFlareContractRegistry constant FLARE_CONTRACT_REGISTRY =
        IFlareContractRegistry(0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019);

    /// Canonical name of the FTSO registry for lookups from the Flare contract
    /// registry.
    string constant FTSO_REGISTRY_NAME = "FtsoRegistry";

    /// Sugar for getting the FTSO registry address from the Flare contract
    /// registry.
    function getFtsoRegistry() internal view returns (IFtsoRegistry) {
        return IFtsoRegistry(FLARE_CONTRACT_REGISTRY.getContractAddressByName(FTSO_REGISTRY_NAME));
    }
}
