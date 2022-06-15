// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITokenFees} from "./interfaces/ITokenFees";

contract GaslessVaultFees {
    mapping(address => uint256) public tokenFee;

    function setTokenFees(address _token) public {
        return uint256(new ITokenFees(_token));
    }

    function getTokenFees(address _token) external view returns (uint256) {
        return tokenFee[_token];
    }
}
