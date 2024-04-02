// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PeopleStableCoin
 * @author Prince Sharma
 * collateral : Exogenous (ETH & WBTC)
 * Minting : Algorithmic
 * relative stability : Pegged to USD
 * it will be goverend by PSCEngine only
 */
contract PeopleStableCoin is ERC20Burnable, Ownable {
    ///// errors //////
    error PSC__BurnAmountExceededBalance();
    error PSC__AmountShouldBEGreaterThanZero();
    error PSC__AddressMustBeMoreThanZero();

    constructor(
        address _DSCEngine
    ) ERC20("PSC", "PeopleStableCoin") Ownable(_DSCEngine) {}

    function mint(
        address sender,
        uint256 amount
    ) external onlyOwner returns (bool) {
        if (amount <= 0) revert PSC__AmountShouldBEGreaterThanZero();
        if (sender == address(0)) revert PSC__AddressMustBeMoreThanZero();

        _mint(sender, amount);
        return true;
    }

    function burn(address sender, uint256 amount) external onlyOwner {
        if (sender == address(0)) revert PSC__AddressMustBeMoreThanZero();
        if (amount <= 0) revert PSC__AmountShouldBEGreaterThanZero();
        uint256 balance = balanceOf(sender);
        if (balance < amount) revert PSC__BurnAmountExceededBalance();

        burnFrom(sender, amount);
    }
}
