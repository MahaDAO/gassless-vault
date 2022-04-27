//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GaslessERC20Depositor {
    address public ecosystemFund;

    IERC20 public token;
    address public vault;

    constructor(address _token) // address _vaultAddress,
    // address _owner
    {
        token = IERC20(_token);
    }

    function stakeToken(uint256 _amount) public {
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawAmount(address userAddress) public {
        uint256 bal = token.balanceOf(address(this));
        token.transfer(userAddress, (bal * 99) / 1000);
        token.transfer(ecosystemFund, bal / 1000);
    }
}
