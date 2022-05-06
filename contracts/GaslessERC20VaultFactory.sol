// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GaslessERC20Vault} from "./GaslessERC20Vault.sol";

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

struct MetaTransaction {
    uint256 nonce;
    address from;
}

// GaslessERC20VaultFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
contract GaslessERC20VaultFactory {
    uint256 constant chainID = 56;
    mapping(address => uint256) public nonces;
    mapping(address => address) public vaults;

    event Created(address indexed vault, address owner);

    // bytes32 public constant METATRANSACTION_TYPEHASH =
    //     keccak256(bytes("MetaTransaction(uint256 nonce, address from)"));

    // bytes32 public constant EIP712_DOMAIN_TYPEHASH =
    //     keccak256(
    //         bytes(
    //             "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    //         )
    //     );

    // bytes32 public DOMAIN_SEPARATOR =
    //     keccak256(
    //         abi.encode(
    //             EIP712_DOMAIN_TYPEHASH,
    //             "build",
    //             "1",
    //             chainID,
    //             address(this)
    //         )
    //     );

    // deploys a new proxy instance
    // sets custom owner of proxy
    function build(
        address _owner,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public returns (address payable vault) {
        // MetaTransaction memory metaTx = MetaTransaction({
        //     nonce: nonces[_owner],
        //     from: _owner
        // });

        // bytes32 digest = keccak256(
        //     abi.encodePacked(
        //         "\\x19\\x01",
        //         DOMAIN_SEPARATOR,
        //         keccak256(
        //             abi.encode(
        //                 METATRANSACTION_TYPEHASH,
        //                 metaTx.nonce,
        //                 metaTx.from
        //             )
        //         )
        //     )
        // );

        // Verify the _owner with the address recovered from the signatures
        // require(_owner == ecrecover(digest, v, r, s), "invalid-signatures");

        require(vaults[_owner] == address(0), "Vault already created");

        // Verify the _owner is not address zero
        require(_owner != address(0), "invalid-address-0");

        vault = payable(address(new GaslessERC20Vault(_owner, address(this))));
        emit Created(vault, _owner);
        vaults[_owner] = vault;
    }

    function transferToken(
        address token,
        address from,
        address to,
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        // MetaTransaction memory metaTx = MetaTransaction({
        //     nonce: nonces[_owner],
        //     from: _owner
        // });

        // bytes32 digest = keccak256(
        //     abi.encodePacked(
        //         "\\x19\\x01",
        //         DOMAIN_SEPARATOR,
        //         keccak256(
        //             abi.encode(
        //                 METATRANSACTION_TYPEHASH,
        //                 metaTx.nonce,
        //                 metaTx.from
        //             )
        //         )
        //     )
        // );

        // Verify the _owner with the address recovered from the signatures
        // require(_owner == ecrecover(digest, v, r, s), "invalid-signatures");

        // Verify the _owner is not address zero
        require(vaults[from] != address(0), "no vault for user");

        GaslessERC20Vault vault = GaslessERC20Vault(vaults[from]);
        vault.transferToken(token, amount, to);
    }
}
