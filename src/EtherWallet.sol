// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // If the signature is valid, return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

contract EtherWallet {
    address payable public owner;
    mapping(bytes32 => bool) public usedSignatures;

    event OwnershipTaken(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
    }

    // everyone with a valid signature can call this, in case of an emergency
    function emergencyWithdraw(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(!usedSignatures[keccak256(abi.encodePacked(v, r, s))]);
        require(
            ECDSA.recover(
                keccak256("\x19Ethereum Signed Message:\n32"),
                v,
                r,
                s
            ) == owner
        );

        usedSignatures[keccak256(abi.encodePacked(v, r, s))] = true;
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function takeOwnership(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(!usedSignatures[keccak256(abi.encodePacked(v, r, s))]);
        require(
            ECDSA.recover(
                keccak256("\x19Ethereum Signed Message:\n32"),
                v,
                r,
                s
            ) == owner
        );

        usedSignatures[keccak256(abi.encodePacked(v, r, s))] = true;
        address oldOwner = owner;
        owner = payable(msg.sender);

        emit OwnershipTaken(oldOwner, msg.sender);
    }
}
