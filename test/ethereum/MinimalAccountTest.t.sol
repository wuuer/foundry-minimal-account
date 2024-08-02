// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployMinimalAccount} from "../../script/DeployMinimalAccount.s.sol";
import {MinimalAccount} from "../../src/ethereum/MinimalAccount.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp} from "../../script/SendPackedUserOp.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/contracts/core/Helpers.sol";

contract MinimalAccountTest is Test {
    MinimalAccount private minimalAccount;
    address deployer;
    ERC20Mock token;
    SendPackedUserOp sendPackedUserOp;
    HelperConfig config;

    function setUp() external {
        DeployMinimalAccount deploy = new DeployMinimalAccount();
        (minimalAccount, deployer, config) = deploy.run();
        token = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    function testOwnerCanExecuteCommands() public {
        assertEq(token.balanceOf(address(minimalAccount)), 0);
        address dest = address(token);
        uint256 mintAmount = 100 ether;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), mintAmount);

        vm.prank(deployer);
        minimalAccount.execute(dest, 0, functionData);
        assertEq(token.balanceOf(address(minimalAccount)), mintAmount);
    }

    function testNonOwnerCantExecuteCommands() public {
        address dest = address(token);
        uint256 mintAmount = 100 ether;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), mintAmount);

        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(dest, 0, functionData);
    }

    function testRecoverSignedOp() public {
        address dest = address(token);
        uint256 mintAmount = 100 ether;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), mintAmount);

        vm.startPrank(deployer);
        // simulate alt-mempool calling the entryPoint
        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, 0, functionData);
        (PackedUserOperation memory data,) =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, address(minimalAccount), config);

        IEntryPoint entryPoint = IEntryPoint(config.entryPoint());
        //bytes memory signature = data.signature;
        // data.signature = hex"";

        bytes32 userOphash = entryPoint.getUserOpHash(data);

        address owner = ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(userOphash), data.signature);

        assertEq(owner, deployer);

        vm.stopPrank();
    }

    function testValidationOfUserOps() public {
        address dest = address(token);
        uint256 mintAmount = 100 ether;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), mintAmount);

        // simulate alt-mempool calling the entryPoint
        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, 0, functionData);
        vm.prank(deployer);
        (PackedUserOperation memory userOp, bytes32 userOpHash) =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, address(minimalAccount), config);

        // simulate entryPoint
        vm.prank(address(config.entryPoint()));
        uint256 result = minimalAccount.validateUserOp(userOp, userOpHash, 1 ether);
        assertEq(result, SIG_VALIDATION_SUCCESS);
    }

    function testEntryPointCanExecuteCommands() public {
        assertEq(token.balanceOf(address(minimalAccount)), 0);
        address dest = address(token);
        uint256 mintAmount = 100 ether;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), mintAmount);

        // simulate alt-mempool calling the entryPoint
        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, 0, functionData);
        vm.prank(deployer);
        (PackedUserOperation memory userOp, bytes32 userOpHash) =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, address(minimalAccount), config);

        vm.deal(address(minimalAccount), 1 ether);

        address randomUser = makeAddr("randomUser");
        IEntryPoint entryPoint = IEntryPoint(config.entryPoint());
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;
        vm.prank(randomUser);
        entryPoint.handleOps(ops, payable(randomUser));
        assertEq(token.balanceOf(address(minimalAccount)), mintAmount);
    }
}
