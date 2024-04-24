// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {PeopleStableCoin} from "../src/PeopleStableCoin.sol";
import {PSCEngine} from "../src/PSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployPSC is Script {
    address[] public tokenAddresses;
    address[] public tokensPricefeed;

    function run()
        external
        returns (PeopleStableCoin, PSCEngine, HelperConfig)
    {
        HelperConfig helperConfig = new HelperConfig();
        (
            address wethAddress,
            address wbtcAddress,
            address wethPricefeed,
            address wbtcPricefeed
        ) = helperConfig.networkConfigAddresses();
        tokenAddresses = [wethAddress, wbtcAddress];
        tokensPricefeed = [wethPricefeed, wbtcPricefeed];

        vm.startBroadcast(address(123456789));
        PSCEngine PSContract = new PSCEngine(tokenAddresses, tokensPricefeed);
        PeopleStableCoin PSCoinContract = new PeopleStableCoin(
            address(PSContract)
        );
        PSContract._initialize(address(PSCoinContract));
        vm.stopBroadcast();

        return (PSCoinContract, PSContract, helperConfig);
    }
}
