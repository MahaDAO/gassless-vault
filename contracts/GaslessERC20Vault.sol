//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IFactory} from "./interfaces/IFactory.sol";

contract GaslessERC20Vault {
    using SafeMath for uint256;
    IFactory public factory;
    address public owner;
    address public me;

    constructor(address _owner, address _factory) {
        owner = _owner;
        factory = IFactory(_factory);
        me = address(this);
    }

    modifier onlyFactoryOrOwner() {
        require(
            msg.sender == owner || msg.sender == address(factory),
            "not owner or factory"
        );
        _;
    }

    function transferERC20(
        address _token,
        uint256 amount,
        address recipient
    ) public onlyFactoryOrOwner {
        IERC20 token = IERC20(_token);

        // Verify the _owner is not address zero
        require(
            token.balanceOf(address(this)) >= amount,
            "insufficient balance"
        );
        require(amount > 0, "invalid amount");

        uint256 fees = amount.div(factory.getEcosystemFee());

        // this contract gives fees to ecosystem
        token.transfer(recipient, amount.sub(fees));
        token.transfer(factory.getEcosystemFund(), fees);
    }

    function transferETH(uint256 amount, address recipient)
        public
        payable
        onlyFactoryOrOwner
    {
        // Verify the _owner is not address zero
        require(me.balance >= amount, "insufficient balance");
        require(amount > 0, "invalid amount");

        uint256 fees = amount.div(factory.getEcosystemFee());

        // send fees to the ecosystem fund
        payable(recipient).transfer(amount.sub(fees));
        payable(factory.getEcosystemFund()).transfer(fees);
    }

    function callFunction(address target, bytes memory signature)
        external
        onlyFactoryOrOwner
    {
        (bool success, bytes memory response) = target.call(signature);
        require(success, string(response));
    }
}
