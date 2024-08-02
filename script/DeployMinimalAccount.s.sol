// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMinimalAccount is Script {
    function run() external returns (MinimalAccount, address, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address entryPointAddress, address deployer) = helperConfig.i_activeNetworkConfig();
        vm.startBroadcast(deployer);
        MinimalAccount minimalAccount = new MinimalAccount(entryPointAddress);
        vm.stopBroadcast();
        return (minimalAccount, deployer, helperConfig);
    }
}
