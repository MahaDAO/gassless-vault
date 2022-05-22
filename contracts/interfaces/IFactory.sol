// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    event Created(address indexed vault, address owner);
    event EcosystemFundChanged(address whom, address fund);
    event EcosystemFeeChanged(address whom, uint256 fee);
    event VaultImplementationChanged(address whom, address impl);

    function getVaultImplementation() external view returns (address);

    function getEcosystemFund() external view returns (address);

    function getEcosystemFee() external view returns (uint256);
}
