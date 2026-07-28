// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {FtsoTest, OperandV2, StackItem} from "../../../abstract/FtsoTest.sol";
import {LibFtsoCurrentPriceUsd} from "src/lib/price/LibFtsoCurrentPriceUsd.sol";
import {DecimalsTooLarge, StalePrice} from "src/err/ErrFtso.sol";
import {LibIntOrAString, IntOrAString} from "rain-intorastring-0.1.0/src/lib/LibIntOrAString.sol";

/// @title LibFtsoCurrentPriceUsdTest
/// @notice Exercises `LibFtsoCurrentPriceUsd.ftsoCurrentPriceUsd` DIRECTLY,
/// without going through `LibOpFtsoCurrentPriceUsd`. The FTSO is untrusted, so
/// the bounds it enforces on FTSO-reported values MUST hold for every caller of
/// the library, not just the one op that happens to call it today.
contract LibFtsoCurrentPriceUsdTest is FtsoTest {
    using LibIntOrAString for IntOrAString;

    /// External wrapper so `vm.expectRevert` monitors the correct call frame.
    /// The library function is `internal`, so an inline call would revert in the
    /// test frame itself rather than in a call `vm.expectRevert` intercepts.
    function externalFtsoCurrentPriceUsd(string memory symbol, uint256 timeout)
        external
        view
        returns (uint256, uint256)
    {
        return LibFtsoCurrentPriceUsd.ftsoCurrentPriceUsd(symbol, timeout);
    }

    /// Satisfies `FtsoTest` so the inherited registry-failure tests exercise the
    /// library directly. Outputs are `[price, decimals]`.
    function externalRun(OperandV2, StackItem[] memory inputs) external view override returns (StackItem[] memory) {
        IntOrAString symbol;
        uint256 timeout;
        assembly ("memory-safe") {
            symbol := mload(add(inputs, 0x20))
            timeout := mload(add(inputs, 0x40))
        }
        (uint256 price, uint256 decimals) = LibFtsoCurrentPriceUsd.ftsoCurrentPriceUsd(symbol.toStringV3(), timeout);
        StackItem[] memory outputs = new StackItem[](2);
        outputs[0] = StackItem.wrap(bytes32(price));
        outputs[1] = StackItem.wrap(bytes32(decimals));
        return outputs;
    }

    /// Mocks a well formed, finalized, non-stale FTSO reporting `currentPrice`.
    function mockHealthyFtso(string memory symbol, PriceDetails memory priceDetails, CurrentPrice memory currentPrice)
        internal
    {
        conformPriceDetails(priceDetails, currentPrice);
        finalizePrice(priceDetails);

        mockRegistry();
        mockFtsoRegistry(FTSO, symbol);
        activateFtso();
        mockPriceDetails(priceDetails);
        mockPrice(FTSO, currentPrice);
    }

    /// In bound decimals are returned to the caller unchanged, alongside the raw
    /// price. This is the oracle the guard is protecting: the library never
    /// rescales, it only bounds.
    function testFtsoCurrentPriceUsdHappy(
        string memory symbol,
        uint256 timeout,
        uint256 currentTime,
        PriceDetails memory priceDetails,
        CurrentPrice memory currentPrice
    ) external {
        currentPrice.price = bound(currentPrice.price, 0, uint256(int256(type(int224).max)));
        currentPrice.decimals = bound(currentPrice.decimals, 0, type(uint8).max);
        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));
        currentTime = warpNotStale(currentPrice, timeout, currentTime);

        mockHealthyFtso(symbol, priceDetails, currentPrice);

        (uint256 price, uint256 decimals) = this.externalFtsoCurrentPriceUsd(symbol, timeout);
        assertEq(price, currentPrice.price, "price");
        assertEq(decimals, currentPrice.decimals, "decimals");
    }

    /// An FTSO reporting more decimals than fit in a uint8 MUST be rejected by
    /// the library itself, with the offending value in the error data. Without
    /// this bound a direct caller would silently downcast to `uint8` and
    /// mis-scale the price by orders of magnitude.
    function testFtsoCurrentPriceUsdDecimalsTooLargeReverts(
        string memory symbol,
        uint256 timeout,
        uint256 currentTime,
        PriceDetails memory priceDetails,
        CurrentPrice memory currentPrice
    ) external {
        currentPrice.price = bound(currentPrice.price, 0, uint256(int256(type(int224).max)));
        currentPrice.decimals =
            bound(currentPrice.decimals, uint256(type(uint8).max) + 1, uint256(int256(type(int32).max)));
        timeout = bound(timeout, 0, uint256(int256(type(int224).max)));
        currentTime = warpNotStale(currentPrice, timeout, currentTime);

        mockHealthyFtso(symbol, priceDetails, currentPrice);

        vm.expectRevert(abi.encodeWithSelector(DecimalsTooLarge.selector, currentPrice.decimals));
        this.externalFtsoCurrentPriceUsd(symbol, timeout);
    }

    /// The exact boundary, low side: `type(uint8).max` decimals is the largest
    /// value that survives the downcast, so it MUST be accepted and returned
    /// verbatim. Pins the `>` in the guard against being weakened to `>=`.
    function testFtsoCurrentPriceUsdDecimalsBoundaryMaxAccepted() external {
        string memory symbol = "ETH";
        uint256 timeout = 3600;

        CurrentPrice memory currentPrice;
        currentPrice.price = 98765;
        currentPrice.decimals = uint256(type(uint8).max);
        currentPrice.timestamp = 50000;
        vm.warp(currentPrice.timestamp);

        PriceDetails memory priceDetails;
        mockHealthyFtso(symbol, priceDetails, currentPrice);

        (uint256 price, uint256 decimals) = this.externalFtsoCurrentPriceUsd(symbol, timeout);
        assertEq(price, 98765, "price");
        assertEq(decimals, uint256(type(uint8).max), "decimals");
    }

    /// The exact boundary, high side: one more than `type(uint8).max` MUST
    /// revert, carrying the unclamped value. Pins the `>` in the guard against
    /// being widened to `type(uint8).max + 1` or dropped entirely.
    function testFtsoCurrentPriceUsdDecimalsBoundaryOverMaxReverts() external {
        string memory symbol = "ETH";
        uint256 timeout = 3600;

        CurrentPrice memory currentPrice;
        currentPrice.price = 98765;
        currentPrice.decimals = uint256(type(uint8).max) + 1;
        currentPrice.timestamp = 50000;
        vm.warp(currentPrice.timestamp);

        PriceDetails memory priceDetails;
        mockHealthyFtso(symbol, priceDetails, currentPrice);

        vm.expectRevert(abi.encodeWithSelector(DecimalsTooLarge.selector, uint256(type(uint8).max) + 1));
        this.externalFtsoCurrentPriceUsd(symbol, timeout);
    }

    /// Staleness is checked before the decimals bound, so a stale price with
    /// oversized decimals reports StalePrice rather than DecimalsTooLarge. Pins
    /// the guard's position at the end of the checks, where it cannot mask an
    /// earlier failure.
    function testFtsoCurrentPriceUsdStaleTakesPrecedenceOverDecimals() external {
        string memory symbol = "ETH";
        uint256 timeout = 3600;

        CurrentPrice memory currentPrice;
        currentPrice.price = 98765;
        currentPrice.decimals = uint256(type(uint8).max) + 1;
        currentPrice.timestamp = 50000;
        // One second past the staleness boundary.
        vm.warp(currentPrice.timestamp + timeout + 1);

        PriceDetails memory priceDetails;
        mockHealthyFtso(symbol, priceDetails, currentPrice);

        vm.expectRevert(abi.encodeWithSelector(StalePrice.selector, currentPrice.timestamp, timeout));
        this.externalFtsoCurrentPriceUsd(symbol, timeout);
    }
}
