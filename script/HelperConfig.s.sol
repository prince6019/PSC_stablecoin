// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "../test/mocks/ERC20Mock.sol";

contract HelperConfig is Script {
    struct networkAddresses {
        address WETHaddress;
        address WBTCaddress;
        address WETHPricefeed;
        address WBTCPricefeed;
    }
    networkAddresses public networkConfigAddresses;

    constructor() {
        if (block.chainid == 11155111) {
            networkConfigAddresses = sepoliaETHConfig();
        } else {
            networkConfigAddresses = anvilConfig();
        }
    }

    function sepoliaETHConfig() public pure returns (networkAddresses memory) {
        networkAddresses memory sepoliaConfigAddress = networkAddresses({
            WETHaddress: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            WBTCaddress: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            WETHPricefeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            WBTCPricefeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        });
        return sepoliaConfigAddress;
    }

    function anvilConfig() public returns (networkAddresses memory) {
        if (networkConfigAddresses.WETHaddress != address(0)) {
            return networkConfigAddresses;
        }
        vm.startBroadcast();
        MockV3Aggregator WethPricefeed = new MockV3Aggregator(8, 2000e8);
        MockV3Aggregator WbtcPricefeed = new MockV3Aggregator(8, 60000e8);
        ERC20Mock WethErc20Mock = new ERC20Mock("wrapped ETH", "WETH");
        ERC20Mock WbtcErc20Mock = new ERC20Mock("wrapped BTC", "WBTC");

        vm.stopBroadcast();

        networkAddresses memory anvilConfigAddress = networkAddresses({
            WETHaddress: address(WethErc20Mock),
            WBTCaddress: address(WbtcErc20Mock),
            WETHPricefeed: address(WethPricefeed),
            WBTCPricefeed: address(WbtcPricefeed)
        });

        return anvilConfigAddress;
    }
}
