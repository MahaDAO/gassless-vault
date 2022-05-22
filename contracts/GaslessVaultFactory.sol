// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GaslessVault} from "./GaslessVault.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFactory} from "./interfaces/IFactory.sol";

// GaslessVaultFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
contract GaslessVaultFactory is Ownable, IFactory {
    uint256 immutable chainID;
    address public ecosystemFund;
    uint256 public ecosystemFee;

    mapping(address => uint256) public nonces;
    mapping(address => address) public vaults;

    // various hashes
    bytes32 public immutable BUILD_HASH = keccak256(bytes("BUILD_HASH"));
    bytes32 public immutable ETH_TRANSFER_HASH =
        keccak256(bytes("ETH_TRANSFER_HASH"));
    bytes32 public immutable ERC20_TRANSFER_HASH =
        keccak256(bytes("ERC20_TRANSFER_HASH"));
    bytes32 public immutable CALL_FN_HASH = keccak256(bytes("CALL_FN_HASH"));
    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() {
        chainID = block.chainid;

        bytes32 typehash = keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(typehash, "build", "1", block.chainid, address(this))
        );

        ecosystemFund = msg.sender;
    }

    // deploys a new proxy instance
    // sets custom owner of proxy
    function build(
        uint256 nonce,
        address whom,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public returns (address payable vault) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\\x19\\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(BUILD_HASH, nonce, whom))
            )
        );

        _checkNonce(whom, nonce);

        // Verify the _owner with the address recovered from the signatures
        require(whom == ecrecover(digest, v, r, s), "invalid-signatures");

        require(vaults[whom] == address(0), "Vault already created");

        // Verify the _owner is not address zero
        require(whom != address(0), "invalid-address-0");

        vault = payable(address(new GaslessVault(whom, address(this))));
        emit Created(vault, whom);
        vaults[whom] = vault;
    }

    function transferToken(
        uint256 nonce,
        address token,
        address from,
        address to,
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        _checkNonce(from, nonce);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\\x19\\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        ERC20_TRANSFER_HASH,
                        nonce,
                        token,
                        from,
                        to,
                        amount
                    )
                )
            )
        );

        // Verify the _owner with the address recovered from the signatures
        require(from == ecrecover(digest, v, r, s), "invalid-signatures");

        // Verify the _owner is not address zero
        require(vaults[from] != address(0), "no vault for user");

        GaslessVault vault = GaslessVault(vaults[from]);
        vault.transferERC20(token, amount, to);
    }

    function transferETH(
        uint256 nonce,
        address from,
        address to,
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        _checkNonce(from, nonce);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\\x19\\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(ETH_TRANSFER_HASH, nonce, from, to, amount)
                )
            )
        );

        // Verify the _owner with the address recovered from the signatures
        require(from == ecrecover(digest, v, r, s), "invalid-signatures");

        // Verify the _owner is not address zero
        require(vaults[from] != address(0), "no vault for user");

        GaslessVault vault = GaslessVault(vaults[from]);
        vault.transferETH(amount, to);
    }

    function callFunction(
        uint256 nonce,
        address from,
        address to,
        bytes memory signature,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        _checkNonce(from, nonce);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\\x19\\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(CALL_FN_HASH, nonce, from, to, signature))
            )
        );

        // Verify the _owner with the address recovered from the signatures
        require(from == ecrecover(digest, v, r, s), "invalid-signatures");

        // Verify the _owner is not address zero
        require(vaults[from] != address(0), "no vault for user");

        GaslessVault vault = GaslessVault(vaults[from]);
        vault.callFunction(to, signature);
    }

    function setEcosystemFund(address _fund) external onlyOwner {
        ecosystemFund = _fund;
        emit EcosystemFundChanged(msg.sender, _fund);
    }

    function setEcosystemFee(uint256 _fee) external onlyOwner {
        ecosystemFee = _fee;
        emit EcosystemFeeChanged(msg.sender, _fee);
    }

    function getEcosystemFund() external view override returns (address) {
        return ecosystemFund;
    }

    function getEcosystemFee() external view override returns (uint256) {
        return ecosystemFee;
    }

    function _checkNonce(address who, uint256 nonce) internal {
        require(nonces[who] < nonce, "nonce too old");
        nonces[who] = nonce;
    }
}
