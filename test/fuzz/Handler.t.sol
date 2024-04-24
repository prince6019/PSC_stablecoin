// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {PSCEngine} from "../../src/PSCEngine.sol";
import {PeopleStableCoin} from "../../src/PeopleStableCoin.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

// depositandMint
// redeemAndBurn
// depositCollateral
// reedeemCollateral
// mintPSC
// burnPSC

contract Handler is Test {
    PSCEngine psce;
    PeopleStableCoin psc;
    ERC20Mock weth;
    ERC20Mock wbtc;
    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;
    address[] collateralDepositedAddresses;

    constructor(address _psce, address _psc, address _weth, address _wbtc) {
        psce = PSCEngine(_psce);
        psc = PeopleStableCoin(_psc);
        weth = ERC20Mock(_weth);
        wbtc = ERC20Mock(_wbtc);
    }

    function depositCollateral(
        uint256 randomValue,
        uint256 _collateralAmount
    ) public {
        address _collateralAddress = get_collateralAddress(randomValue);
        uint256 collateralValue = bound(_collateralAmount, 1, MAX_DEPOSIT_SIZE);
        if (collateralValue < 1e15) return;
        vm.startPrank(msg.sender);
        ERC20Mock(_collateralAddress).mint(msg.sender, collateralValue);
        ERC20Mock(_collateralAddress).approve(address(psce), collateralValue);
        psce.depositCollateral(_collateralAddress, collateralValue);
        vm.stopPrank();
        collateralDepositedAddresses.push(msg.sender);
    }

    function redeemCollateral(uint256 randomValue, uint256 amount) public {
        address _collateralAddress = get_collateralAddress(randomValue);
        uint256 maxCollateralValue = psce.getUserCollateral(
            msg.sender,
            _collateralAddress
        );
        if (maxCollateralValue == 0) return;

        uint256 collateralValue = bound(amount, 0, maxCollateralValue);
        if (collateralValue == 0) {
            return;
        }
        vm.startPrank(msg.sender);
        psce.redeemCollateral(_collateralAddress, collateralValue, msg.sender);
        vm.stopPrank();
    }

    function mintPsc(uint256 randomValue, uint256 amountToMint) public {
        if (collateralDepositedAddresses.length == 0) return;
        address _userAddress = collateralDepositedAddresses[
            randomValue % collateralDepositedAddresses.length
        ];
        (uint256 userCollateralInUsd, uint256 pscMinted) = psce
            .getUserAccountInfo(_userAddress);
        int256 maxPscMinted = (int256(userCollateralInUsd) * 100) /
            150 -
            int256(pscMinted);
        if (maxPscMinted <= 0) {
            return;
        }
        amountToMint = bound(amountToMint, 0, uint256(maxPscMinted));
        if (amountToMint == 0) return;
        vm.prank(_userAddress);
        psce.mintToken(_userAddress, amountToMint);
    }

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
