// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GaslessVaultProxy} from "./GaslessVaultProxy.sol";
import {GaslessVaultInstance} from "./GaslessVaultInstance.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IVault} from "./interfaces/IVault.sol";

// GaslessVaultFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
contract GaslessVaultFactory is Ownable, IFactory {
    uint256 private immutable chainID;
    address private ecosystemFund;
    uint256 private ecosystemFee;
    address private vaultImplementation;

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

        vaultImplementation = address(new GaslessVaultInstance());
    }

    // deploys a new proxy instance
    // sets custom owner of proxy
    function build(
        uint256 nonce,
        address whom,
        bytes memory sig
    ) public returns (address payable vault) {
        bytes32 digest = prefixed(
            keccak256(abi.encode(BUILD_HASH, nonce, whom))
        );

        _checkNonce(whom, nonce);

        // Verify the _owner with the address recovered from the signatures
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        require(whom == ecrecover(digest, v, r, s), "invalid-signatures");

        require(vaults[whom] == address(0), "Vault already created");

        // Verify the _owner is not address zero
        require(whom != address(0), "invalid-address-0");

        vault = payable(address(new GaslessVaultProxy(address(this))));
        emit Created(vault, whom);
        vaults[whom] = vault;

        // init vault
        IVault(vault).initialize(whom, address(this));
    }

    function transferToken(
        uint256 nonce,
        address token,
        address from,
        address to,
        uint256 amount,
        bytes memory sig
    ) external {
        _checkNonce(from, nonce);

        bytes32 digest = prefixed(
            keccak256(
                abi.encode(ERC20_TRANSFER_HASH, nonce, token, from, to, amount)
            )
        );

        // Verify the _owner with the address recovered from the signatures
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        require(from == ecrecover(digest, v, r, s), "invalid-signatures");

        // Verify the _owner is not address zero
        require(vaults[from] != address(0), "no vault for user");

        GaslessVaultInstance vault = GaslessVaultInstance(vaults[from]);
        vault.transferERC20(token, amount, to);
    }

    function transferETH(
        uint256 nonce,
        address from,
        address to,
        uint256 amount,
        bytes memory sig
    ) external {
        _checkNonce(from, nonce);

        bytes32 digest = prefixed(
            keccak256(abi.encode(ETH_TRANSFER_HASH, nonce, from, to, amount))
        );

        // Verify the _owner with the address recovered from the signatures
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        require(from == ecrecover(digest, v, r, s), "invalid-signatures");

        // Verify the _owner is not address zero
        require(vaults[from] != address(0), "no vault for user");

        GaslessVaultInstance vault = GaslessVaultInstance(vaults[from]);
        vault.transferETH(amount, to);
    }

    function callFunction(
        uint256 nonce,
        address from,
        address to,
        bytes memory fnSignature,
        bytes memory sig
    ) external {
        _checkNonce(from, nonce);

        bytes32 digest = prefixed(
            keccak256(abi.encode(CALL_FN_HASH, nonce, from, to, fnSignature))
        );

        // Verify the _owner with the address recovered from the signatures
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        require(from == ecrecover(digest, v, r, s), "invalid-signatures");

        // Verify the _owner is not address zero
        require(vaults[from] != address(0), "no vault for user");

        GaslessVaultInstance vault = GaslessVaultInstance(vaults[from]);
        vault.callFunction(to, fnSignature);
    }

    function setEcosystemFund(address _fund) external onlyOwner {
        ecosystemFund = _fund;
        emit EcosystemFundChanged(msg.sender, _fund);
    }

    function setEcosystemFee(uint256 _fee) external onlyOwner {
        ecosystemFee = _fee;
        emit EcosystemFeeChanged(msg.sender, _fee);
    }

    function setVaultImplementation(address _vaultImplementation)
        external
        onlyOwner
    {
        vaultImplementation = _vaultImplementation;
        emit VaultImplementationChanged(msg.sender, vaultImplementation);
    }

    function getVaultImplementation() external view override returns (address) {
        return vaultImplementation;
    }

    function getEcosystemFund() external view override returns (address) {
        return ecosystemFund;
    }

    function getEcosystemFee() external view override returns (uint256) {
        return ecosystemFee;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hashstr) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hashstr)
            );
    }

    function _checkNonce(address who, uint256 nonce) internal {
        require(nonces[who] < nonce, "nonce too old");
        nonces[who] = nonce;
    }
}
