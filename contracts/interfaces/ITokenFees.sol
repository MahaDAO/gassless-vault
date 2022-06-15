// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenFees {
    function setTokenFee(address _token) external;

    function getTokenFee(address _token) external view returns (uint256);
}
