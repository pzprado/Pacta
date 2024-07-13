// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AgreementStorage} from "./AgreementStorage.sol";
import {EventsLib} from "./libraries/EventsLib.sol";

contract Shotgun is AgreementStorage {
    using EventsLib for *;

    function createAgreement(address _party1, address _party2, address _token, uint256 _duration)
        external
        returns (uint256)
    {
        agreementCounter++;
        agreements[agreementCounter] = Agreement({
            party1: _party1,
            party2: _party2,
            token: _token,
            duration: _duration,
            bound: false,
            party1Approved: false,
            party2Approved: false,
            currentOffer: Offer({
                token: _token,
                price: 0,
                tokenAmount: 0,
                offeror: address(0),
                expiry: 0,
                active: false,
                staked: false
            })
        });

        emit EventsLib.AgreementCreated(agreementCounter, _party1, _party2, _token, _duration);
        return agreementCounter;
    }

    function makeOffer(address token, uint256 price, uint256 shares, uint256 duration) external {
        require(!currentOffer.active, "An offer is already active.");
        require(IERC20(token).balanceOf(msg.sender) >= shares, "Insufficient shares to make offer.");

        currentOffer = Offer({
            token: token,
            price: price,
            shares: shares,
            offeror: msg.sender,
            expiry: block.timestamp + duration,
            active: true
        });

        emit OfferMade(msg.sender, token, price, shares, currentOffer.expiry);
    }

    function acceptOffer() external {
        require(currentOffer.active, "No active offer.");
        require(block.timestamp <= currentOffer.expiry, "Offer has expired.");
        require(
            IERC20(currentOffer.token).balanceOf(msg.sender) >= currentOffer.shares,
            "Insufficient shares to accept offer."
        );

        IERC20(currentOffer.token).transferFrom(msg.sender, currentOffer.offeror, currentOffer.shares);
        payable(msg.sender).transfer(currentOffer.shares * currentOffer.price);

        currentOffer.active = false;
        emit OfferAccepted(msg.sender);
    }

    function counterOffer() external payable {
        require(currentOffer.active, "No active offer.");
        require(block.timestamp <= currentOffer.expiry, "Offer has expired.");
        require(msg.value == currentOffer.shares * currentOffer.price, "Incorrect ETH amount sent.");

        IERC20(currentOffer.token).transferFrom(currentOffer.offeror, msg.sender, currentOffer.shares);
        payable(currentOffer.offeror).transfer(msg.value);

        currentOffer.active = false;
        emit CounterOfferMade(msg.sender);
    }

    function expireOffer() external {
        require(currentOffer.active, "No active offer.");
        require(block.timestamp > currentOffer.expiry, "Offer has not expired yet.");

        currentOffer.active = false;
        emit OfferExpired();
    }

    // Withdraw funds from contract
    function withdraw(uint256 amount) external {
        payable(owner()).transfer(amount);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
