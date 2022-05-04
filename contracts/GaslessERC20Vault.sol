//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GaslessERC20Vault {
    uint256 constant chainID = 3;
    address constant ecosystemFund = 0x9790C67E6062ce2965517E636377B954FA2d1afA;
    address public vault;
    uint256 public fees;

    function transferToken(
        address _token,
        address userAddress,
        uint256 amount,
        address recipient
    ) public payable {
        IERC20 token = IERC20(_token);

        // Verify the _owner is not address zero
        require(userAddress != address(0), "invalid-address-0");
        uint256 bal = token.balanceOf(userAddress);
        require(bal >= amount, "Insufficient Balance");
        require(amount > 0, "Insufficient Funds");

        fees = amount / 1000;

        token.transferFrom(userAddress, address(this), amount);
        // this contract gives fees to ecosystem
        token.transfer(recipient, amount - fees);
        token.transfer(ecosystemFund, fees);
    }
}
