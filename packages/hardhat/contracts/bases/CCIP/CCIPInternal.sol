// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { CCIPStorage } from "./CCIPStorage.sol";

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
contract CCIPInternal {
	// Custom errors to provide more descriptive revert messages.
	error InvalidRouter(address router);
	error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.
	error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
	error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
	error DestinationChainNotAllowlisted(uint64 destinationChainSelector); // Used when the destination chain has not been allowlisted by the contract owner.
	error SourceChainNotAllowed(uint64 sourceChainSelector); // Used when the source chain has not been allowlisted by the contract owner.
	error SenderNotAllowed(address sender); // Used when the sender has not been allowlisted by the contract owner.
	error OnlySelf(); // Used when a function is called outside of the contract itself.
	error ErrorCase(); // Used when simulating a revert during message processing.
	error MessageNotFailed(bytes32 messageId);

	// Example error code, could have many different error codes.
	enum ErrorCode {
		// RESOLVED is first so that the default value is resolved.
		RESOLVED,
		// Could have any number of error codes here.
		BASIC
	}

	// Event emitted when a message is sent to another chain.
	event CrossChainBurnAndMintMessageSent(
		bytes32 indexed messageId, // The unique ID of the CCIP message.
		uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
		address receiver, // The address of the receiver on the destination chain.
		uint256 tokenId, // the tokenId of the NFT being moved.
		address feeToken, // the token address used to pay CCIP fees.
		uint256 fees // The fees paid for sending the message.
	);

	// Event emitted when a message is sent to another chain.
	event MessageSent(
		bytes32 indexed messageId, // The unique ID of the CCIP message.
		uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
		address receiver, // The address of the receiver on the destination chain.
		string text, // The text being sent.
		address token, // The token address that was transferred.
		uint256 tokenAmount, // The token amount that was transferred.
		address feeToken, // the token address used to pay CCIP fees.
		uint256 fees // The fees paid for sending the message.
	);

	// Event emitted when a message is received from another chain.
	event MessageReceived(
		bytes32 indexed messageId, // The unique ID of the CCIP message.
		uint64 indexed sourceChainSelector, // The chain selector of the source chain.
		address sender, // The address of the sender from the source chain.
		string text, // The text that was received.
		address token, // The token address that was transferred.
		uint256 tokenAmount // The token amount that was transferred.
	);

	event MessageFailed(bytes32 indexed messageId, bytes reason);
	event MessageRecovered(bytes32 indexed messageId);

	event MintCallSuccessfull();

	/// @dev only calls from the set router are accepted.
	modifier onlyRouter() {
		if (msg.sender != address(CCIPStorage._getCCIPStorage().i_router))
			revert InvalidRouter(msg.sender);
		_;
	}

	/// @notice Return the current router
	/// @return i_router address
	function _getRouter() internal view returns (address) {
		return address(CCIPStorage._getCCIPStorage().i_router);
	}

	/// @dev Modifier that checks if the chain with the given destinationChainSelector is allowlisted.
	/// @param _destinationChainSelector The selector of the destination chain.
	modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
		if (
			!CCIPStorage._getCCIPStorage().allowlistedDestinationChains[
				_destinationChainSelector
			]
		) revert DestinationChainNotAllowlisted(_destinationChainSelector);
		_;
	}

	/// @dev Modifier that checks if the chain with the given sourceChainSelector is allowlisted and if the sender is allowlisted.
	/// @param _sourceChainSelector The selector of the destination chain.
	/// @param _sender The address of the sender.
	modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
		if (
			!CCIPStorage._getCCIPStorage().allowlistedSourceChains[
				_sourceChainSelector
			]
		) revert SourceChainNotAllowed(_sourceChainSelector);
		if (!CCIPStorage._getCCIPStorage().allowlistedSenders[_sender])
			revert SenderNotAllowed(_sender);
		_;
	}

	/// @dev Modifier to allow only the contract itself to execute a function.
	/// Throws an exception if called by any account other than the contract itself.
	modifier onlySelf() {
		if (msg.sender != address(this)) revert OnlySelf();
		_;
	}

	function _ccipReceive(
		Client.Any2EVMMessage memory message
	) internal virtual {
		(bool success, ) = address(this).call(message.data);
		require(success);
		emit MintCallSuccessfull();
	}

	// -------------------------------- SENDING MESSAGES ------------------------- //

	/// @notice Construct a CCIP message.
	/// @dev This function will create an EVM2AnyMessage struct with all the necessary information for programmable tokens transfer.
	/// @param _receiver The address of the receiver.
	/// @param _text The string data to be sent.
	/// @param _token The token to be transferred.
	/// @param _amount The amount of the token to be transferred.
	/// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
	/// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
	function _buildCCIPMessage(
		address _receiver,
		string calldata _text,
		address _token,
		uint256 _amount,
		address _feeTokenAddress
	) internal pure returns (Client.EVM2AnyMessage memory) {
		// Set the token amounts
		Client.EVMTokenAmount[]
			memory tokenAmounts = new Client.EVMTokenAmount[](1);
		Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
			token: _token,
			amount: _amount
		});
		tokenAmounts[0] = tokenAmount;
		// Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
		Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
			receiver: abi.encode(_receiver), // ABI-encoded receiver address
			data: abi.encode(_text), // ABI-encoded string
			tokenAmounts: tokenAmounts, // The amount and type of token being transferred
			extraArgs: Client._argsToBytes(
				// Additional arguments, setting gas limit
				Client.EVMExtraArgsV1({ gasLimit: 2_000_000 })
			),
			// Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
			feeToken: _feeTokenAddress
		});
		return evm2AnyMessage;
	}
}
