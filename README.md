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