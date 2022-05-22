//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IERCProxy} from "./interfaces/IERCProxy.sol";

contract GaslessVaultProxy is IERCProxy, Context {
    IFactory public proxyFactory;

    constructor(address _factory) {
        proxyFactory = IFactory(_factory);
    }

    fallback() external payable {
        delegatedFwd(loadImplementation(), msg.data);
    }

    receive() external payable {
        delegatedFwd(loadImplementation(), _msgData());
    }

    function implementation() external view override returns (address) {
        return loadImplementation();
    }

    function loadImplementation() internal view returns (address) {
        return proxyFactory.getVaultImplementation();
    }

    function delegatedFwd(address _dst, bytes memory _calldata) internal {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let result := delegatecall(
                sub(gas(), 10000),
                _dst,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize()

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    function proxyType()
        external
        pure
        virtual
        override
        returns (uint256 proxyTypeId)
    {
        // Upgradeable proxy
        proxyTypeId = 2;
    }
}
