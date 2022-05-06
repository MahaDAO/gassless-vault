//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GaslessERC20Vault {
    address constant ecosystemFund = 0x9790C67E6062ce2965517E636377B954FA2d1afA;
    uint256 public fees;

    address public factory;
    address public owner;

    constructor(address _owner, address _factory) {
        owner = _owner;
        factory = _factory;
    }

    function transferToken(
        address _token,
        uint256 amount,
        address recipient
    ) public payable {
        require(
            msg.sender == owner || msg.sender == factory,
            "not owner or factory"
        );

        IERC20 token = IERC20(_token);

        // Verify the _owner is not address zero
        require(
            token.balanceOf(address(this)) >= amount,
            "insufficient balance"
        );
        require(amount > 0, "invalid amount");

        fees = amount / 1000;

        // this contract gives fees to ecosystem
        token.transfer(recipient, amount - fees);
        token.transfer(ecosystemFund, fees);
    }
}
