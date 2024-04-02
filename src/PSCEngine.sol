// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PeopleStableCoin} from "./PeopleStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// collateral -> eth , wbtc;
contract PSCEngine is Ownable {
    ///// errors //////
    //////////////////
    error PSCEngine_tokensAndPricefeedLengthNotMatch();
    error PSCEngine_TokenNotSupported();
    error PSCEngine_AmountTooLow();
    error PSCEngine_healthFactorBroken();

    PeopleStableCoin private i_PeopleStableCoin;

    using SafeERC20 for IERC20;

    ///// state variables //////
    ///////////////////////////
    uint256 private constant healthThreshold = 150;
    uint256 private constant health_precision = 100;
    uint256 private constant PRICEFEED_PRECISION = 1e10;

    mapping(address => mapping(address => uint256)) private s_userCollateral;
    mapping(address token => address pricefeed) private s_pricefeeds;
    mapping(address => uint256) private TokenMinted;
    address[] private tokensAddress;

    /////// events ///////
    /////////////////////
    event CollateralDeposited(
        address indexed user,
        address token,
        uint256 amount
    );
    event PSCMinted(address indexed user, uint256 amount);
    event PSCBurnt(address indexed user, uint256 amount);
    event collateralRedeemed(
        address indexed user,
        address token,
        uint256 amountWithdrawn
    );

    //////constructor//////
    //////////////////////

    constructor(
        address[] memory _tokens,
        address[] memory _pricefeeds
    ) Ownable(msg.sender) {
        if (_tokens.length != _pricefeeds.length)
            revert PSCEngine_tokensAndPricefeedLengthNotMatch();

        for (uint i = 0; i < _tokens.length; i++) {
            s_pricefeeds[_tokens[i]] = _pricefeeds[i];
            tokensAddress.push(_tokens[i]);
        }
    }

    function _initialize(address _peopleStableCoin) external onlyOwner {
        i_PeopleStableCoin = PeopleStableCoin(_peopleStableCoin);
    }

    /// functions/////
    //////////////////

    function depositCollateralAndMintToken(
        address _collateralToken,
        uint256 _collateral,
        uint256 _amountOfPSCToMint
    ) external {
        depositCollateral(_collateralToken, _collateral);
        mintToken(msg.sender, _amountOfPSCToMint);
    }

    function burnTokensAndWithdrawCollateral(
        address _collateralTokenToWithdraw,
        uint256 amountOfCollateralToken,
        uint256 amountOfPSCToBurn
    ) external {
        burnPSC(amountOfPSCToBurn, msg.sender);
        redeemCollateral(
            _collateralTokenToWithdraw,
            amountOfCollateralToken,
            msg.sender
        );
        if (HealthFactorBroken(msg.sender))
            revert PSCEngine_healthFactorBroken();
    }

    function depositCollateral(
        address _collateralToken,
        uint256 _collateral
    ) public {
        if (s_pricefeeds[_collateralToken] == address(0))
            revert PSCEngine_TokenNotSupported();
        // if (_collateral < 1e15) revert PSCEngine_AmountTooLow();
        s_userCollateral[msg.sender][_collateralToken] += _collateral;
        IERC20(_collateralToken).safeTransferFrom(
            msg.sender,
            address(this),
            _collateral
        ); /// safeTransferFrom
        emit CollateralDeposited(msg.sender, _collateralToken, _collateral);
    }

    function mintToken(address _user, uint256 _amount) public {
        TokenMinted[_user] += _amount;
        if (HealthFactorBroken(_user)) revert PSCEngine_healthFactorBroken();
        i_PeopleStableCoin.mint(_user, _amount);
        emit PSCMinted(_user, _amount);
    }

    function redeemCollateral(
        address _collateralToken,
        uint256 _amonuntOfCollateralToken,
        address _user
    ) public {
        if (s_pricefeeds[_collateralToken] == address(0))
            revert PSCEngine_TokenNotSupported();
        if (
            _amonuntOfCollateralToken == 0 ||
            _amonuntOfCollateralToken >
            s_userCollateral[_user][_collateralToken]
        ) revert PSCEngine_AmountTooLow();

        s_userCollateral[_user][_collateralToken] -= _amonuntOfCollateralToken;
        if (HealthFactorBroken(_user)) revert PSCEngine_healthFactorBroken();
        IERC20(_collateralToken).safeTransferFrom(
            address(this),
            _user,
            _amonuntOfCollateralToken
        );
        emit collateralRedeemed(
            _user,
            _collateralToken,
            _amonuntOfCollateralToken
        );
    }

    function burnPSC(uint256 amountOfPSCToBurn, address _user) public {
        TokenMinted[_user] -= amountOfPSCToBurn;
        if (TokenMinted[_user] != 0) {
            if (HealthFactorBroken(_user))
                revert PSCEngine_healthFactorBroken();
        }
        i_PeopleStableCoin.burn(_user, amountOfPSCToBurn);
        if (HealthFactorBroken(_user)) revert PSCEngine_healthFactorBroken();
        emit PSCBurnt(_user, amountOfPSCToBurn);
    }

    function liquidate(address _user) public view {
        if (!HealthFactorBroken(_user)) revert PSCEngine_healthFactorBroken();
    }

    function HealthFactorBroken(address _user) public view returns (bool) {
        uint256 healthFactor = getHealthFactor(_user);
        if (healthFactor < healthThreshold) {
            return true;
        } else {
            return false;
        }
    }

    function getHealthFactor(address _user) public view returns (uint256) {
        (
            uint256 UserCollateralInUsd,
            uint256 userPSCMinted
        ) = getUserAccountInfo(_user);
        uint256 healthFactor = (UserCollateralInUsd * health_precision) /
            userPSCMinted;
        return healthFactor;
    }

    /**
     *
     * @param _user: address of the user
     * @return userCollateral total collateral of the user in USD
     * @return pscMinted total amount of the PSC token owned by the user
     */

    function getUserAccountInfo(
        address _user
    ) public view returns (uint256 userCollateral, uint256 pscMinted) {
        pscMinted = TokenMinted[_user];
        userCollateral = getUserCollateralInUsd(_user);
    }

    /**
     * @notice returns the total collateral of the user in USD across all the token address of collateral deposited
     * @param _user :address of the user of collateral to be calculated
     */

    function getUserCollateralInUsd(
        address _user
    ) public view returns (uint256 userCollateral) {
        uint256 totalCollateralInUsd = 0;
        for (uint256 i = 0; i < tokensAddress.length; i++) {
            address _token = tokensAddress[i];
            uint256 _collateral = s_userCollateral[_user][_token];
            uint256 tokenPrice = getPriceFeed(_token);
            uint256 collateralInUsd = (tokenPrice * _collateral) / 1e18;
            totalCollateralInUsd += collateralInUsd;
        }
        return totalCollateralInUsd;
    }

    /**
     * @notice returns the value of the token in USD
     * @param token: address of the token address
     */

    function getPriceFeed(address token) public view returns (uint256) {
        (, int answer, , , ) = AggregatorV3Interface(s_pricefeeds[token])
            .latestRoundData();
        return uint256(answer) * PRICEFEED_PRECISION;
    }

    ////// view functions////
    ////////////////////////

    function getUserTotalCollateralInUsd(
        address _user
    ) external view returns (uint256) {
        return getUserCollateralInUsd(_user);
    }

    function getUserCollateral(
        address _user,
        address _tokenAddress
    ) external view returns (uint256) {
        return s_userCollateral[_user][_tokenAddress];
    }

    function getHealthThreshold() external pure returns (uint256) {
        return healthThreshold;
    }

    function getHealthPrecision() external pure returns (uint256) {
        return health_precision;
    }

    function getUserPSC(address _user) external view returns (uint256) {
        return TokenMinted[_user];
    }

    function gettokenAddressesSupported()
        external
        view
        returns (address[] memory)
    {
        return tokensAddress;
    }

    function getPSC() external view returns (address) {
        return address(i_PeopleStableCoin);
    }

    // receive() external payable {}
}
