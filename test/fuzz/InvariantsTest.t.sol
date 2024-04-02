// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployPSC} from "../../script/DeployPSC.s.sol";
import {PSCEngine} from "../../src/PSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {PeopleStableCoin} from "../../src/PeopleStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant {
    DeployPSC deployer;
    PSCEngine _pscEngine;
    HelperConfig _helperConfig;
    PeopleStableCoin _peopleStableCoin;
    IERC20 weth;
    IERC20 wbtc;

    function setUp() public {
        deployer = new DeployPSC();
        (_peopleStableCoin, _pscEngine, _helperConfig) = deployer.run();
        (address _weth, address _wbtc, , ) = _helperConfig
            .networkConfigAddresses();
        weth = IERC20(_weth);
        wbtc = IERC20(_wbtc);

        Handler handler = new Handler(
            address(_pscEngine),
            address(_peopleStableCoin),
            _weth,
            _wbtc
        );
        targetContract(address(handler));
    }

    function invariant_protocolShouldAlwaysBeOverCollateralised() public view {
        uint256 totalCollateral = _peopleStableCoin.totalSupply();
        uint256 wethBalance = weth.balanceOf(address(_pscEngine));
        uint256 wbtcBalance = wbtc.balanceOf(address(_pscEngine));
        uint256 wethValue = _pscEngine.getPriceFeed(address(weth)) *
            wethBalance;
        uint256 wbtcValue = _pscEngine.getPriceFeed(address(wbtc)) *
            wbtcBalance;
        assert(wethValue + wbtcValue >= totalCollateral);
    }
}
