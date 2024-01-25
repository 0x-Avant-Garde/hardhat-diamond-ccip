// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { AccessControlInternal } from "../../bases/AccessControl/AccessControlInternal.sol";
import { UseStorage } from "../../core/UseStorage.sol";

contract AccessControlFacet is AccessControlInternal, UseStorage {
	/**
	 * @dev Returns `true` if `account` has been granted `role`.
	 */

	function hasRole(
		bytes32 role,
		address account
	) public view virtual returns (bool) {
		return acl()._roles[role].hasRole[account];
	}

	/**
	 * @dev Returns the admin role that controls `role`. See {grantRole} and
	 * {revokeRole}.
	 *
	 * To change a role's admin, use {_setRoleAdmin}.
	 */
	function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
		return acl()._roles[role].adminRole;
	}

	/**
	 * @dev Grants `role` to `account`.
	 *
	 * If `account` had not been already granted `role`, emits a {RoleGranted}
	 * event.
	 *
	 * Requirements:
	 *
	 * - the caller must have ``role``'s admin role.
	 *
	 * May emit a {RoleGranted} event.
	 */
	function grantRole(
		bytes32 role,
		address account
	) public virtual onlyRole(getRoleAdmin(role)) {
		_grantRole(role, account);
	}

	/**
	 * @dev Revokes `role` from `account`.
	 *
	 * If `account` had been granted `role`, emits a {RoleRevoked} event.
	 *
	 * Requirements:
	 *
	 * - the caller must have ``role``'s admin role.
	 *
	 * May emit a {RoleRevoked} event.
	 */
	function revokeRole(
		bytes32 role,
		address account
	) public virtual onlyRole(getRoleAdmin(role)) {
		_revokeRole(role, account);
	}

	/**
	 * @dev Revokes `role` from the calling account.
	 *
	 * Roles are often managed via {grantRole} and {revokeRole}: this function's
	 * purpose is to provide a mechanism for accounts to lose their privileges
	 * if they are compromised (such as when a trusted device is misplaced).
	 *
	 * If the calling account had been revoked `role`, emits a {RoleRevoked}
	 * event.
	 *
	 * Requirements:
	 *
	 * - the caller must be `callerConfirmation`.
	 *
	 * May emit a {RoleRevoked} event.
	 */
	function renounceRole(
		bytes32 role,
		address callerConfirmation
	) public virtual {
		if (callerConfirmation != msg.sender) {
			revert AccessControlBadConfirmation();
		}

		_revokeRole(role, callerConfirmation);
	}
}
