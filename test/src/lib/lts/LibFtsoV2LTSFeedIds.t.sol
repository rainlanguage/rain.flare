// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {
    FLR_USD_FEED_ID,
    SGB_USD_FEED_ID,
    BTC_USD_FEED_ID,
    XRP_USD_FEED_ID,
    LTC_USD_FEED_ID,
    XLM_USD_FEED_ID,
    DOGE_USD_FEED_ID,
    ADA_USD_FEED_ID,
    ALGO_USD_FEED_ID,
    ETH_USD_FEED_ID,
    FIL_USD_FEED_ID,
    ARB_USD_FEED_ID,
    AVAX_USD_FEED_ID,
    BNB_USD_FEED_ID,
    POL_USD_FEED_ID,
    SOL_USD_FEED_ID,
    USDC_USD_FEED_ID,
    USDT_USD_FEED_ID,
    XDC_USD_FEED_ID,
    TRX_USD_FEED_ID,
    JOULE_USD_FEED_ID
} from "src/lib/lts/LibFtsoV2LTS.sol";

/// @title LibFtsoV2LTSFeedIdsTest
/// @notice Asserts the exact value and Flare-defined derivation of every FTSO
/// feed-id constant declared in LibFtsoV2LTS.sol.
///
/// A Flare V2 feed id is a `bytes21` structured as one category byte followed
/// by the feed name encoded as ASCII, right-padded with zero bytes:
///   feedId = bytes1(category) ++ bytes(asciiName) ++ zeroPadding(to 21 bytes)
/// The category byte for crypto (USD-denominated) pairs is `0x01`. See
/// https://dev.flare.network/ftso/feeds .
///
/// These are pure value assertions and do not touch the network: they pin the
/// literal hex of each constant, prove each constant is reproduced by the
/// derivation rule from its human-readable name, and prove the constants are
/// distinct from one another. A typo in any constant — even one that still
/// happens to resolve on-chain — is caught here, which the live fork tests
/// cannot guarantee.
contract LibFtsoV2LTSFeedIdsTest is Test {
    /// @dev The category byte that prefixes every crypto/USD feed id.
    bytes1 internal constant CRYPTO_CATEGORY = 0x01;

    /// Derive a Flare V2 feed id from a category byte and a feed name.
    /// The name is encoded as ASCII and the result is right-padded with zero
    /// bytes to the full `bytes21` width. Reverts (via the require) if the
    /// category byte plus name do not fit in 21 bytes.
    function deriveFeedId(bytes1 category, string memory name) internal pure returns (bytes21) {
        bytes memory nameBytes = bytes(name);
        require(nameBytes.length <= 20, "name too long for bytes21 feed id");

        bytes memory packed = new bytes(21);
        packed[0] = category;
        for (uint256 i = 0; i < nameBytes.length; i++) {
            packed[i + 1] = nameBytes[i];
        }
        return bytes21(packed);
    }

    /// The category byte of a feed id is its first (most significant) byte.
    function categoryByteOf(bytes21 feedId) internal pure returns (bytes1) {
        return bytes1(feedId);
    }

    /// Every constant matches the literal hex value Flare publishes for it.
    /// This pins the source so an accidental edit to any constant fails here.
    function testFeedIdLiterals() external pure {
        assertEq(FLR_USD_FEED_ID, bytes21(0x01464c522f55534400000000000000000000000000), "FLR/USD");
        assertEq(SGB_USD_FEED_ID, bytes21(0x015347422f55534400000000000000000000000000), "SGB/USD");
        assertEq(BTC_USD_FEED_ID, bytes21(0x014254432f55534400000000000000000000000000), "BTC/USD");
        assertEq(XRP_USD_FEED_ID, bytes21(0x015852502f55534400000000000000000000000000), "XRP/USD");
        assertEq(LTC_USD_FEED_ID, bytes21(0x014c54432f55534400000000000000000000000000), "LTC/USD");
        assertEq(XLM_USD_FEED_ID, bytes21(0x01584c4d2f55534400000000000000000000000000), "XLM/USD");
        assertEq(DOGE_USD_FEED_ID, bytes21(0x01444f47452f555344000000000000000000000000), "DOGE/USD");
        assertEq(ADA_USD_FEED_ID, bytes21(0x014144412f55534400000000000000000000000000), "ADA/USD");
        assertEq(ALGO_USD_FEED_ID, bytes21(0x01414c474f2f555344000000000000000000000000), "ALGO/USD");
        assertEq(ETH_USD_FEED_ID, bytes21(0x014554482f55534400000000000000000000000000), "ETH/USD");
        assertEq(FIL_USD_FEED_ID, bytes21(0x0146494c2f55534400000000000000000000000000), "FIL/USD");
        assertEq(ARB_USD_FEED_ID, bytes21(0x014152422f55534400000000000000000000000000), "ARB/USD");
        assertEq(AVAX_USD_FEED_ID, bytes21(0x01415641582f555344000000000000000000000000), "AVAX/USD");
        assertEq(BNB_USD_FEED_ID, bytes21(0x01424e422f55534400000000000000000000000000), "BNB/USD");
        assertEq(POL_USD_FEED_ID, bytes21(0x01504f4c2f55534400000000000000000000000000), "POL/USD");
        assertEq(SOL_USD_FEED_ID, bytes21(0x01534f4c2f55534400000000000000000000000000), "SOL/USD");
        assertEq(USDC_USD_FEED_ID, bytes21(0x01555344432f555344000000000000000000000000), "USDC/USD");
        assertEq(USDT_USD_FEED_ID, bytes21(0x01555344542f555344000000000000000000000000), "USDT/USD");
        assertEq(XDC_USD_FEED_ID, bytes21(0x015844432f55534400000000000000000000000000), "XDC/USD");
        assertEq(TRX_USD_FEED_ID, bytes21(0x015452582f55534400000000000000000000000000), "TRX/USD");
        assertEq(JOULE_USD_FEED_ID, bytes21(0x014a4f554c452f5553440000000000000000000000), "JOULE/USD");
    }

    /// Every constant is reproduced by the Flare derivation rule applied to its
    /// human-readable feed name with the crypto category byte. This proves the
    /// constants encode the names they claim to, independently of the literal
    /// pinning above.
    function testFeedIdDerivation() external pure {
        assertEq(FLR_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "FLR/USD"), "FLR/USD");
        assertEq(SGB_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "SGB/USD"), "SGB/USD");
        assertEq(BTC_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "BTC/USD"), "BTC/USD");
        assertEq(XRP_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "XRP/USD"), "XRP/USD");
        assertEq(LTC_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "LTC/USD"), "LTC/USD");
        assertEq(XLM_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "XLM/USD"), "XLM/USD");
        assertEq(DOGE_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "DOGE/USD"), "DOGE/USD");
        assertEq(ADA_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "ADA/USD"), "ADA/USD");
        assertEq(ALGO_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "ALGO/USD"), "ALGO/USD");
        assertEq(ETH_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "ETH/USD"), "ETH/USD");
        assertEq(FIL_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "FIL/USD"), "FIL/USD");
        assertEq(ARB_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "ARB/USD"), "ARB/USD");
        assertEq(AVAX_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "AVAX/USD"), "AVAX/USD");
        assertEq(BNB_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "BNB/USD"), "BNB/USD");
        assertEq(POL_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "POL/USD"), "POL/USD");
        assertEq(SOL_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "SOL/USD"), "SOL/USD");
        assertEq(USDC_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "USDC/USD"), "USDC/USD");
        assertEq(USDT_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "USDT/USD"), "USDT/USD");
        assertEq(XDC_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "XDC/USD"), "XDC/USD");
        assertEq(TRX_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "TRX/USD"), "TRX/USD");
        assertEq(JOULE_USD_FEED_ID, deriveFeedId(CRYPTO_CATEGORY, "JOULE/USD"), "JOULE/USD");
    }

    /// Every feed id carries the crypto category byte `0x01` in its first byte.
    function testFeedIdCategoryByte() external pure {
        assertEq(categoryByteOf(FLR_USD_FEED_ID), CRYPTO_CATEGORY, "FLR/USD");
        assertEq(categoryByteOf(SGB_USD_FEED_ID), CRYPTO_CATEGORY, "SGB/USD");
        assertEq(categoryByteOf(BTC_USD_FEED_ID), CRYPTO_CATEGORY, "BTC/USD");
        assertEq(categoryByteOf(XRP_USD_FEED_ID), CRYPTO_CATEGORY, "XRP/USD");
        assertEq(categoryByteOf(LTC_USD_FEED_ID), CRYPTO_CATEGORY, "LTC/USD");
        assertEq(categoryByteOf(XLM_USD_FEED_ID), CRYPTO_CATEGORY, "XLM/USD");
        assertEq(categoryByteOf(DOGE_USD_FEED_ID), CRYPTO_CATEGORY, "DOGE/USD");
        assertEq(categoryByteOf(ADA_USD_FEED_ID), CRYPTO_CATEGORY, "ADA/USD");
        assertEq(categoryByteOf(ALGO_USD_FEED_ID), CRYPTO_CATEGORY, "ALGO/USD");
        assertEq(categoryByteOf(ETH_USD_FEED_ID), CRYPTO_CATEGORY, "ETH/USD");
        assertEq(categoryByteOf(FIL_USD_FEED_ID), CRYPTO_CATEGORY, "FIL/USD");
        assertEq(categoryByteOf(ARB_USD_FEED_ID), CRYPTO_CATEGORY, "ARB/USD");
        assertEq(categoryByteOf(AVAX_USD_FEED_ID), CRYPTO_CATEGORY, "AVAX/USD");
        assertEq(categoryByteOf(BNB_USD_FEED_ID), CRYPTO_CATEGORY, "BNB/USD");
        assertEq(categoryByteOf(POL_USD_FEED_ID), CRYPTO_CATEGORY, "POL/USD");
        assertEq(categoryByteOf(SOL_USD_FEED_ID), CRYPTO_CATEGORY, "SOL/USD");
        assertEq(categoryByteOf(USDC_USD_FEED_ID), CRYPTO_CATEGORY, "USDC/USD");
        assertEq(categoryByteOf(USDT_USD_FEED_ID), CRYPTO_CATEGORY, "USDT/USD");
        assertEq(categoryByteOf(XDC_USD_FEED_ID), CRYPTO_CATEGORY, "XDC/USD");
        assertEq(categoryByteOf(TRX_USD_FEED_ID), CRYPTO_CATEGORY, "TRX/USD");
        assertEq(categoryByteOf(JOULE_USD_FEED_ID), CRYPTO_CATEGORY, "JOULE/USD");
    }

    /// All feed-id constants are pairwise distinct. A copy-paste duplicate
    /// (two names mapped to the same id) is caught here.
    function testFeedIdsAreUnique() external pure {
        bytes21[21] memory feedIds = [
            FLR_USD_FEED_ID,
            SGB_USD_FEED_ID,
            BTC_USD_FEED_ID,
            XRP_USD_FEED_ID,
            LTC_USD_FEED_ID,
            XLM_USD_FEED_ID,
            DOGE_USD_FEED_ID,
            ADA_USD_FEED_ID,
            ALGO_USD_FEED_ID,
            ETH_USD_FEED_ID,
            FIL_USD_FEED_ID,
            ARB_USD_FEED_ID,
            AVAX_USD_FEED_ID,
            BNB_USD_FEED_ID,
            POL_USD_FEED_ID,
            SOL_USD_FEED_ID,
            USDC_USD_FEED_ID,
            USDT_USD_FEED_ID,
            XDC_USD_FEED_ID,
            TRX_USD_FEED_ID,
            JOULE_USD_FEED_ID
        ];
        for (uint256 i = 0; i < feedIds.length; i++) {
            for (uint256 j = i + 1; j < feedIds.length; j++) {
                assertTrue(feedIds[i] != feedIds[j], "duplicate feed id");
            }
        }
    }
}
