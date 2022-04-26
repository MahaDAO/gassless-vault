//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct EIP712Domain {
    string name;
    uint256 chainId;
    address verifyingContract;
}

struct MetaTransaction {
    uint256 nonce;
    address from;
}

contract GaslessERC20Vault {
    mapping(address => uint256) public nonces;
    address public ecosystemF

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
            )
        );

    bytes32 internal constant META_TRANSACTION_TYPEHASH =
        keccak256(bytes("MetaTransaction(uint256 nonce,address from)"));

    bytes32 internal DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("1")),
                4,
                address(this)
            )
        );

    IERC20 token;

    constructor(address _token) public {
        token = IERC20(_token);
    }

    function stakeToken(uint256 _amount) public {
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawAmount(
        address userAddress,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress
        });
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        META_TRANSACTION_TYPEHASH,
                        metaTx.nonce,
                        metaTx.from
                    )
                )
            )
        );

        // Verify the userAddress is not address zero
        require(userAddress != address(0), "invalid-address-0");

        // Verify the userAddress with the address recovered from the signatures
        // require(userAddress == ecrecover(digest, v, r, s), "invalid-signatures");
        uint256 bal = token.balanceOf(address(this));
        token.transfer(userAddress, (bal * 99) / 1000);
        token.transfer(address(this), bal / 1000);
    }

    receive() external payable {}
}
