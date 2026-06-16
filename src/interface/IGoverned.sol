// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {IGovernanceSettings} from "../vendor/flare-smart-contracts/userInterfaces/IGovernanceSettings.sol";

interface IGoverned {
    /// @dev Returns the address of the current governance account.
    function governance() external view returns (address);

    /// @dev Returns the governance settings contract which specifies the
    /// timelocked executors and other governance parameters.
    function governanceSettings() external returns (IGovernanceSettings);

    /// @dev Executes a previously-submitted governance proposal identified by
    /// its 4-byte function selector, after the timelock has elapsed.
    /// @param selector The 4-byte selector of the governance call to execute.
    function executeGovernanceCall(bytes4 selector) external;
}
