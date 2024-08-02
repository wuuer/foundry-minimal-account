// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {EntryPoint} from "account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address entryPointAddress;
        address deployer;
    }

    NetworkConfig public i_activeNetworkConfig;
    EntryPoint public entryPoint;
    address private constant DEPLOY_ACCOUNT = 0xA041129E84bFC1D2b29bCe9Fa309FdEB708fb477;
    address private constant DEPLOY_ANVIL_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    constructor() {
        // sepolia online testnet
        if (block.chainid == 11155111) {
            i_activeNetworkConfig = getSepoliaConfig();
        }
        // zkSync online testnet
        else if (block.chainid == 300) {
            i_activeNetworkConfig = getzkSyncConfig();
        }
        // anvil local network
        else {
            i_activeNetworkConfig = getOrCreateAnilConfig();
        }
    }

    function getSepoliaConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPointAddress: 0x0576a174D229E3cFA37253523E645A78A0C91B57, deployer: DEPLOY_ACCOUNT});
    }

    function getzkSyncConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPointAddress: address(0), deployer: DEPLOY_ACCOUNT});
    }

    function getOrCreateAnilConfig() private returns (NetworkConfig memory) {
        if (i_activeNetworkConfig.entryPointAddress != address(0)) {
            return i_activeNetworkConfig;
        }

        // mocks
        console.log("Deploying EntryPoint mocks...");

        vm.startBroadcast(DEPLOY_ANVIL_ACCOUNT);

        entryPoint = new EntryPoint();

        vm.stopBroadcast();

        return NetworkConfig({entryPointAddress: address(entryPoint), deployer: DEPLOY_ANVIL_ACCOUNT});
    }
}
