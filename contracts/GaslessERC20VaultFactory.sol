// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GaslessERC20Vault} from "./GaslessERC20Vault.sol";

// GaslessERC20VaultFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
contract GaslessERC20VaultFactory {
    mapping(address => uint256) public nonces;
    mapping(address => address) public vaults;

    event Created(address indexed vault, address owner);

    // deploys a new proxy instance
    // sets custom owner of proxy
    function build(address _owner) public returns (address vault) {
        require(vaults[_owner] == address(0), "Vault already created");

        vault = payable(address(new GaslessERC20Vault(_owner, address(this))));

        emit Created(vault, _owner);
        vaults[_owner] = vault;
    }

    function transferToken(
        address _token,
        address from,
        address to,
        uint256 amount
    ) external {
        require(vaults[from] != address(0), "no vault for user");

        GaslessERC20Vault vault = GaslessERC20Vault(vaults[from]);
        vault.transferToken(_token, amount, to);
    }

    function getABIEncoded(
        address token,
        address from,
        address to,
        uint256 amount
    ) public view returns (bytes memory) {
        return
            abi.encode(
                METATRANSACTION_TRANSFER_TYPEHASH,
                token,
                nonces[from],
                from,
                to,
                amount
            );
    }

    function getABIEncodedPacked(
        address token,
        address from,
        address to,
        uint256 amount
    ) public view returns (bytes memory) {
        return
            abi.encodePacked(
                "\\x19\\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        METATRANSACTION_TRANSFER_TYPEHASH,
                        token,
                        nonces[from],
                        from,
                        to,
                        amount
                    )
                )
            );
    }

    function getDigest(
        address token,
        address from,
        address to,
        uint256 amount
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\\x19\\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            METATRANSACTION_TRANSFER_TYPEHASH,
                            token,
                            nonces[from],
                            from,
                            to,
                            amount
                        )
                    )
                )
            );
    }
}
