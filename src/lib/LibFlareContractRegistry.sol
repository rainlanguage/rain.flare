// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

library LibFlareContractRegistry {
    /// The address of the Flare contract registry.
    /// This is the same and immutable across all Flare networks
    /// (mainnet, testnet, etc).
    /// https://docs.flare.network/dev/getting-started/contract-addresses/
    address constant FLARE_CONTRACT_REGISTRY = 0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019;
}