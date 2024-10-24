// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.25;

import {IGovernanceSettings} from "flare-smart-contracts/userInterfaces/IGovernanceSettings.sol";

interface IGoverned {
    function governance() external view returns (address);
    function governanceSettings() external returns (IGovernanceSettings);
    function executeGovernanceCall(bytes4 selector) external;

}