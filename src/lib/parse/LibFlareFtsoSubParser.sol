// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {AuthoringMetaV2} from "rain.interpreter.interface/interface/IParserV1.sol";

/// @dev Index into the function pointers array for the current USD price.
uint256 constant SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD = 0;
/// @dev Index into the function pointers array for the current pair price.
uint256 constant SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR = 1;
/// @dev The number of function pointers in the array.
uint256 constant SUB_PARSER_WORD_PARSERS_LENGTH = 2;

library LibFlareFtsoSubParser {
    /// Builds the authoring meta for the sub parser. This is used both as data for
    /// tooling directly, and to build the runtime parse meta.
    //slither-disable-next-line dead-code
    function authoringMetaV2() internal pure returns (bytes memory) {
        AuthoringMetaV2[] memory meta = new AuthoringMetaV2[](SUB_PARSER_WORD_PARSERS_LENGTH);
        meta[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_USD] = AuthoringMetaV2(
            "ftso-current-price-usd",
            "Returns the current USD price of the given token according to the FTSO. Accepts 2 inputs, the symbol string used by the FTSO and the timeout in seconds. The price is rounded down if it does not fit in a Rainlang number. The timeout will be used to determine if the price is stale and revert if it is."
        );
        meta[SUB_PARSER_WORD_FTSO_CURRENT_PRICE_PAIR] = AuthoringMetaV2(
            "ftso-current-price-pair",
            "Returns the current price of the given token pair according to the FTSO. Accepts 3 inputs, the symbol string used by the FTSO for the base token, the symbol string used by the FTSO for the quote token and the timeout in seconds. The price is rounded down if it does not fit in a Rainlang number. The timeout will be used to determine if the price is stale and revert if it is. Note that the pair price is derived from two separate FTSO prices mechanically and is not provided directly by the FTSO."
        );
        return abi.encode(meta);
    }
}
