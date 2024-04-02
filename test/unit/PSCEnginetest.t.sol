// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {DeployPSC} from "../../script/DeployPSC.s.sol";
import {PSCEngine} from "../../src/PSCEngine.sol";
import {PeopleStableCoin} from "../../src/PeopleStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract PSCEngineTest is Test {
    address private constant USER_1 = address(2);
    address private constant USER_2 = address(3);
    uint256 USER_1_depositCollateral = 1e18;

    PeopleStableCoin _peopleStableCoin;
    PSCEngine _pscEngine;
    HelperConfig _helperConfig;
    ERC20Mock WethErc20Mock;
    ERC20Mock WbtcErc20Mock;
    ///////////////
    ////errors/////
    ///////////////
    error OwnableUnauthorizedAccount(address account);
    error PSCEngine_TokenNotSupported();
    error PSCEngine_AmountTooLow();
    error PSCEngine_healthFactorBroken();

    ////events/////
    //////////////
    event CollateralDeposited(
        address indexed user,
        address token,
        uint256 amount
    );

    function setUp() public {
        DeployPSC _deployPSC = new DeployPSC();
        (_peopleStableCoin, _pscEngine, _helperConfig) = _deployPSC.run();
        (
            address wethAddress,
            address wbtcAddress,
            address wethPricefeed,
            address wbtcPricefeed
        ) = _helperConfig.networkConfigAddresses();

        WethErc20Mock = ERC20Mock(wethAddress);
        WbtcErc20Mock = ERC20Mock(wbtcAddress);
        WethErc20Mock.mint(USER_1, 10e18);
        WethErc20Mock.mint(USER_2, 10e18);
        WbtcErc20Mock.mint(USER_1, 10e18);
        WbtcErc20Mock.mint(USER_2, 10e18);
        vm.prank(address(123456789));
        _pscEngine._initialize(address(_peopleStableCoin));
        vm.startPrank(USER_1);
        WethErc20Mock.approve(address(_pscEngine), USER_1_depositCollateral);
        WbtcErc20Mock.approve(address(_pscEngine), USER_1_depositCollateral);
        vm.stopPrank();
    }

    modifier depositCollateral() {
        vm.startPrank(USER_1);
        _pscEngine.depositCollateral(
            address(WethErc20Mock),
            USER_1_depositCollateral
        );
        vm.stopPrank();
        _;
    }

    modifier depositAndMint() {
        vm.startPrank(USER_1);
        _pscEngine.depositCollateralAndMintToken(
            address(WethErc20Mock),
            USER_1_depositCollateral,
            1000e18
        );
        vm.stopPrank();
        _;
    }

    // peopleStableCoin test//////
    function testPSCMint() public {
        vm.prank(USER_1);
        vm.expectRevert();
        _peopleStableCoin.mint(USER_1, 1e18);
    }

    function test_revertIfTokenIsNotSupported() public {
        vm.prank(USER_1);
        vm.expectRevert(PSCEngine_TokenNotSupported.selector);
        _pscEngine.depositCollateral(address(5), 1e18);
    }

    function test_revertsIfAmountIsTooLow() public {
        vm.prank(USER_1);
        vm.expectRevert(PSCEngine_AmountTooLow.selector);
        _pscEngine.depositCollateral(address(WethErc20Mock), 1e14);
    }

    function testdepositCollateral() public {
        vm.startPrank(USER_1);
        _pscEngine.depositCollateral(address(WethErc20Mock), 1e18);
        assertEq(
            1e18,
            _pscEngine.getUserCollateral(USER_1, address(WethErc20Mock))
        );
        uint256 balance = WethErc20Mock.balanceOf(USER_1);
        vm.stopPrank();
        console.log("balance of user1 :", balance);
        assertEq(WethErc20Mock.balanceOf(USER_1), 9e18);
    }

    // function testDepositCollateralEmitEvent() public {
    //     vm.prank(USER_1);
    //     vm.expectEmit(true ,true);
    //     emit _pscEngine.depositCollateral(address(WethErc20Mock), 1e18);

    // }

    function test_revertsIfhealthfactorIsBroken() public {
        vm.prank(USER_2);
        vm.expectRevert(PSCEngine_healthFactorBroken.selector);
        _pscEngine.mintToken(USER_2, 10e18);
    }

    function testMintFunction() public depositCollateral {
        vm.prank(USER_1);
        _pscEngine.mintToken(USER_1, 500e18);
        assertEq(_pscEngine.getUserPSC(USER_1), 500e18);
    }

    // function testMintFunctionEmitEvent() public{

    // }

    function testdepositCollateralAndMintToken() public {
        vm.startPrank(USER_1);
        _pscEngine.depositCollateralAndMintToken(
            address(WbtcErc20Mock),
            USER_1_depositCollateral,
            1000e18
        );
        assertEq(_pscEngine.getUserPSC(USER_1), 1000e18);
        assertEq(
            _pscEngine.getUserCollateral(USER_1, address(WbtcErc20Mock)),
            USER_1_depositCollateral
        );
        vm.stopPrank();
    }

    function test_revertsIfAmountisLowInReedemCollateral()
        public
        depositAndMint
    {
        vm.prank(USER_1);
        vm.expectRevert(PSCEngine_AmountTooLow.selector);
        _pscEngine.redeemCollateral(address(WethErc20Mock), 200e18, USER_1);
    }

    function test_redeemCollateral() public depositAndMint {
        vm.startPrank(USER_1);
        _pscEngine.redeemCollateral(address(WethErc20Mock), 1e17, USER_1);
        assertEq(
            _pscEngine.getUserCollateral(USER_1, address(WethErc20Mock)),
            USER_1_depositCollateral - 1e17
        );
        vm.stopPrank();
    }

    // function test_redeemCollateralEmitEvent() public depositAndMint{

    // }

    function test_burnPSC() public depositAndMint {
        vm.startPrank(USER_1);
        _peopleStableCoin.approve(address(_pscEngine), 100e18);
        _pscEngine.burnPSC(100e18, USER_1);
        assertEq(_pscEngine.getUserPSC(USER_1), 900e18);
        vm.stopPrank();
    }

    // function test_burnPscEmitEvent() public depositAndMint{}

    function test_revertsBurnAndreedeemIfhealthfactorIsBroken()
        public
        depositAndMint
    {
        vm.startPrank(USER_1);
        _peopleStableCoin.approve(address(_pscEngine), 100e18);
        vm.expectRevert(PSCEngine_healthFactorBroken.selector);
        _pscEngine.burnTokensAndWithdrawCollateral(
            address(WethErc20Mock),
            5e17,
            100e18
        );

        vm.stopPrank();
    }

    function test_burnAndRedeemCollateral() public depositAndMint {
        vm.startPrank(USER_1);
        _peopleStableCoin.approve(address(_pscEngine), 500e18);

        _pscEngine.burnTokensAndWithdrawCollateral(
            address(WethErc20Mock),
            5e17,
            500e18
        );
        assertEq(_pscEngine.getUserPSC(USER_1), 500e18);
        assertEq(
            _pscEngine.getUserCollateral(USER_1, address(WethErc20Mock)),
            USER_1_depositCollateral - 5e17
        );
        vm.stopPrank();
    }
}
