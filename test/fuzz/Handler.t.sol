// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {PSCEngine} from "../../src/PSCEngine.sol";
import {PeopleStableCoin} from "../../src/PeopleStableCoin.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract Handler is Test {
    PSCEngine psce;
    PeopleStableCoin psc;
    ERC20Mock weth;
    ERC20Mock wbtc;
    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(address _psce, address _psc, address _weth, address _wbtc) {
        psce = PSCEngine(_psce);
        psc = PeopleStableCoin(_psc);
        weth = ERC20Mock(_weth);
        wbtc = ERC20Mock(_wbtc);
    }

    function test_depositCollateral(
        uint256 randomValue,
        uint256 _collateralAmount
    ) public {
        address _collateralAddress = get_collateralAddress(randomValue);
        uint256 collateralValue = bound(_collateralAmount, 1, MAX_DEPOSIT_SIZE);
        vm.startPrank(msg.sender);
        ERC20Mock(_collateralAddress).mint(msg.sender, collateralValue);
        ERC20Mock(_collateralAddress).approve(address(psce), collateralValue);
        psce.depositCollateral(_collateralAddress, collateralValue);
        vm.stopPrank();
    }

    function test_redeemCollateral(uint256 randomValue, uint256 amount) public {
        address _collateralAddress = get_collateralAddress(randomValue);
        uint256 maxCollateralValue = psce.getUserCollateral(
            msg.sender,
            _collateralAddress
        );
        if (maxCollateralValue == 0) return;
        uint256 collateralValue = bound(amount, 0, maxCollateralValue);
        vm.startPrank(msg.sender);
        psce.redeemCollateral(_collateralAddress, collateralValue, msg.sender);
        vm.stopPrank();
    }

    function test_mintPsc() public {}

    // helper function
    function get_collateralAddress(
        uint256 value
    ) public view returns (address) {
        if (value % 2 == 0) {
            return address(weth);
        }
        return address(wbtc);
    }
}
