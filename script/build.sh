#!/usr/bin/env bash
# SPDX-License-Identifier: LicenseRef-DCL-1.0
# SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
# Regenerate committed meta artifacts that the rainix copy-artifacts reusable
# diff-checks. Delegates to the rain-flare-prelude nix task so the build
# recipe has a single definition (flake.nix) rather than being duplicated here.
set -euo pipefail
nix develop -c rain-flare-prelude
