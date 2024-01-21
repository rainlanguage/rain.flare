# rain.flare

Provides an extern and sub parser so that functionality native to Flare Network
is available to rainlang authors.

## Words

`ftso-current-price-usd`

Accepts 2 inputs, the symbol string used by the FTSO and the timeout in seconds.

Attempts to be as conservative as possible and only provide a price if everything
is obviously correct. Fallback/default values never allowed and the word will
revert if there is ever doubt.

For example the word will error if (non exhaustive list):

- The FTSO registry does not exist on the current chain
- An FTSO for the given symbol cannot be found in the registry
- The FTSO is not self reporting as "active"
- The price finalization type is not "weighted median"
  - E.g. the finalization type might be "trusted fallback" which is disallowed
  - E.g. the finalization type might be unknown if the ftso code returns
    something outside the current `IFtso` interface
- The finalisation timestamp of the current price is older than the timeout
  relative to the current block time
- Rescaling prices to 18 decimal fixed point causes an overflow

`ftso-current-price-pair`

Accepts 3 inputs, two symbol strings used by their respective FTSOs and the
timeout in seconds.

Fetches the current USD price for each then derives a new price that is the
price of the first denominated in the second. E.g. at the time of writing,
`ftso-current-price-pair("ETH" "BTC" 3600)` derived price is about 0.06e18 which
is 0.06 in 18 decimal fixed point math.

All the same considerations and behaviours of individual USD prices fetches are
applied to the two internal fetches for this word.

Note that as the price is derived from independent data points, there is no
real FTSO reporting it, and no guarantee the prices are even from the same block.
In theory, a large timeout, coupled with high volatility and large discrepencies
between the two internal FTSO "current price" timestamps could lead to inaccurate
pricings. Using a short timeout should generally mitigate this risk, as FTSO data
points aren't backed by directly tradeable liquidity anyway, and are themselves
derived as a median of several reported values.

Regardless, it is NOT recommended that this word be used for high precision
calculations, as derived prices can drift from reality simply due to differences
in the reporting times.

### Timeouts

The rainlang author must provide a timeout which is used to guarantee that prices
are never older than this many seconds relative to now.

If the author does not care about the age of some price they can simply set this
to the max int value.

FTSOs have several timestamps in their life cycle, as there is a period between
the opening time and finalization time. The timestamps used for stale checks are
the final update times.

### Decimals

The rainlang word always provides prices normalised to 18 decimal fixed point
values. This differs from the underlying FTSO values as the raw data is a tuple
of value and decimals.

The rescaling is generally lossless except in two edge cases:

- When scaling numbers _up_ (i.e. ftso decimals is less than 18) if the final
  value overflows the max `uint256` which is ~1.15^77
- When scaling numbers _down_ (i.e. ftso decimals is more than 18) there can be
  loss of precision for the significant figures beyond 18 decimals

In the latter case of precision loss, rounding is always down as per EVM default
behaviour.

