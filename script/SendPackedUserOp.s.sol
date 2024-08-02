// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {PackedUserOperation} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendPackedUserOp is Script {
    function run() external {}

    function generateSignedUserOperation(bytes memory callData, address minimalAccount, HelperConfig config)
        public
        view
        returns (PackedUserOperation memory, bytes32)
    {
        IEntryPoint entryPoint = IEntryPoint(config.entryPoint());
        uint256 nonce = entryPoint.getNonce(minimalAccount, 1);
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("PRIVATE_KEY"), digest);
        //uint8 v,bytes32 r,bytes32 s) = vm.sign(msg.sender,digest); // use for --account
        userOp.signature = abi.encodePacked(r, s, v);
        return (userOp, userOpHash);
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit), // Packed gas limits for validateUserOp and gas limit passed to the callData method call.
            preVerificationGas: verificationGasLimit, //Gas not calculated by the handleOps method, but added to the gas paid.Covers batch overhead.
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
