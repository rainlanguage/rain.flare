# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Overview

Rain Flare words: a Rainlang extern + sub-parser that exposes Flare FTSO v1
price feeds, FTSO V2 LTS feeds, sFLR (Sceptre Staked FLR) exchange rate, and
flrETH (Dinero) exchange rate as first-class Rainlang opcodes. Deployed as a
single `FlareFtsoWords` contract on Flare mainnet.

## Build Commands

```bash
forge build          # Compile contracts
forge soldeer install  # Install Soldeer dependencies (if dependencies/ missing)
forge test           # Run all Solidity tests (non-fork tests only without RPC)
forge test -vvvv     # Verbose trace output for debugging
```

Fork tests require `RPC_URL_FLARE_FORK` in the environment (default falls back
to Ankr public endpoint — do NOT rely on that for CI):

```bash
RPC_URL_FLARE_FORK=<rpc-url> forge test
```

### Regenerate committed meta artifacts

```bash
./script/build.sh
```

This regenerates `meta/FlareFtsoWords.rain.meta` (needed for describedByMeta
test and deployment). Run it whenever the authoring-meta input changes. The
script calls `forge script BuildAuthoringMeta.sol` then `rain meta build`.

### Regenerate generated pointers

Generated pointer files (`src/generated/FlareFtsoWords.pointers.sol`) are
committed. Regenerate with:

```bash
nix develop -c forge script script/BuildPointers.sol
```

CI (`copy-artifacts`) diffs these files and fails if they drift from source.

## Architecture

- **`src/concrete/FlareFtsoWords.sol`** — the deployed contract; inherits both
  `FlareFtsoExtern` and `FlareFtsoSubParser`.
- **`src/abstract/FlareFtsoExtern.sol`** — extern dispatch: maps opcode indices
  to run/integrity function pointers for the three supported words (ftso-usd,
  ftso-pair, sflr-exchange-rate).
- **`src/abstract/FlareFtsoSubParser.sol`** — sub-parser: maps word names to
  extern call stubs so they appear as native Rainlang words.
- **`src/lib/op/`** — one library per opcode (LibOpFtsoCurrentPriceUsd,
  LibOpFtsoCurrentPricePair, LibOpSFLRCurrentExchangeRate).
- **`src/lib/registry/LibFlareContractRegistry.sol`** — sugar for looking up
  FTSO registry / V2 LTS / FeeCalculator from the immutable Flare contract
  registry address.
- **`src/lib/sflr/LibSceptreStakedFlare.sol`** — reads sFLR/FLR exchange rate
  from the Sceptre staked FLR contract.
- **`src/lib/flreth/LibDineroFlrEth.sol`** — reads ETH/flrETH exchange rate
  from the Dinero flrETH contract.
- **`src/generated/FlareFtsoWords.pointers.sol`** — committed artifact; built
  by `script/BuildPointers.sol`. Do NOT hand-edit.
- **`meta/`** — committed authoring-meta artifacts; built by `script/build.sh`.

## Key Invariants

- The two opcode-index constant sets (`OPCODE_*` in FlareFtsoExtern and
  `SUB_PARSER_WORD_*` in LibFlareFtsoSubParser) must agree by value; a mismatch
  silently misroutes words at runtime. No offline test checks this.
- Fork tests pin specific block numbers (see `test/fork/ForkConstants.sol` for
  canonical values). Value assertions (exchange rates, prices) are coupled to
  these pins; re-pin in ForkConstants.sol, not in individual test files.
- All reusable CI workflows are in the `rainlanguage/rainix` repo.

## License

LicenseRef-DCL-1.0. All source files require SPDX headers per REUSE.toml.
