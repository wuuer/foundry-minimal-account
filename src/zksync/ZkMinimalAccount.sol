// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IAccount} from "era/src/system-contracts/interfaces/IAccount.sol";
import {Transaction} from "era/src/system-contracts/libraries/MemoryTransactionHelper.sol";
import {PackedUserOperation} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/contracts/core/Helpers.sol";

/**
 * Lifecycle of a type 113 (0x71) transaction
 * msg.sender is the bootloadr system contract
 *
 * Phase 1 Validation
 * 1. The user sends the transaction to the "zkSync API client" (sort of a "light code").
 * 2. The zkSync API client checks the nonce unique by querying the NonceHolder system contracts.
 * 3. The zkSync API client calls validationTransaction, which MUST update the nonce.
 * 4. The zkSync API client checks the nonce updated.
 * 5. The zkSync API client calls payForTransaction or prepareForPaymaster & validateAndPeyForPaymasterTransaction
 * 6. The zkSync API client verifies that the bootloader gets paid.
 *
 * Phase 2 Execution
 * 7. The zkSync API client passes the validation transaction to the main node (as of today, they are the same).
 * 8. The main node calls executeTransaction
 *
 *
 */
contract ZkMinimalAccount is IAccount {
    /// @notice Called by the bootloader to validate that an account agrees to process the transaction
    /// (and potentially pay for it).
    /// @param _txHash The hash of the transaction to be used in the explorer
    /// @param _suggestedSignedHash The hash of the transaction is signed by EOAs
    /// @param _transaction The transaction itself
    /// @return magic The magic value that should be equal to the signature of this function
    /// if the user agrees to proceed with the transaction.
    /// @dev The developer should strive to preserve as many steps as possible both for valid
    /// and invalid transactions as this very method is also used during the gas fee estimation
    /// (without some of the necessary data, e.g. signature).

    /**
     * @notice must increase the nonce
     * @notice must validate the transaction (check thie owner signed the transaction)
     * @notice also check to see if we have enough money in our account
     * @param _txHash
     * @param _suggestedSignedHash
     * @param _transaction
     */
    function validateTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
        returns (bytes4 magic)
    {}

    function executeTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
    {}

    // There is no point in providing possible signed hash in the `executeTransactionFromOutside` method,
    // since it typically should not be trusted.
    // you sign tx
    // send your tx to your friends
    // your firends send tx
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable {}

    function payForTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
    {}

    function prepareForPaymaster(bytes32 _txHash, bytes32 _possibleSignedHash, Transaction calldata _transaction)
        external
        payable
    {}
}
