// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AgreementStorage} from "./AgreementStorage.sol";
import {EventsLib} from "./libraries/EventsLib.sol";

contract Shotgun is AgreementStorage {
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

    function approveAgreement(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        require(msg.sender == agreement.party1 || msg.sender == agreement.party2, "Not a party to this agreement.");
        require(!agreement.bound, "Agreement already bound.");

        if (msg.sender == agreement.party1) {
            agreement.party1Approved = true;
        } else if (msg.sender == agreement.party2) {
            agreement.party2Approved = true;
        }

        if (agreement.party1Approved && agreement.party2Approved) {
            agreement.bound = true;
            emit EventsLib.AgreementBound(agreementId);
        }
    }

    function makeOffer(uint256 agreementId, uint256 price, uint256 shares) external payable {
        Agreement storage agreement = agreements[agreementId];
        require(agreement.bound, "Agreement not bound.");
        require(!agreement.currentOffer.active, "An offer is already active.");
        require(msg.sender == agreement.party1 || msg.sender == agreement.party2, "Not a party to this agreement.");
        require(IERC20(agreement.token).balanceOf(msg.sender) >= shares, "Insufficient shares to make offer.");
        require(msg.value == shares * price, "Staking amount incorrect.");

        agreement.currentOffer = Offer({
            token: agreement.token,
            price: price,
            tokenAmount: shares,
            offeror: msg.sender,
            expiry: block.timestamp + agreement.duration,
            active: true,
            staked: true
        });

        emit EventsLib.OfferMade(agreementId, msg.sender, agreement.token, price, shares, agreement.currentOffer.expiry);
    }

    function acceptOffer(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        Offer storage offer = agreement.currentOffer;

        require(offer.active, "No active offer.");
        require(block.timestamp <= offer.expiry, "Offer has expired.");
        require(IERC20(offer.token).balanceOf(msg.sender) >= offer.tokenAmount, "Insufficient shares to accept offer.");
        require(msg.sender == agreement.party1 || msg.sender == agreement.party2, "Not a party to this agreement.");

        IERC20(offer.token).transferFrom(msg.sender, offer.offeror, offer.tokenAmount);
        payable(msg.sender).transfer(offer.tokenAmount * offer.price);

        offer.active = false;
        offer.staked = false;
        emit EventsLib.OfferAccepted(agreementId, msg.sender);
    }

    function counterOffer(uint256 agreementId) external payable {
        Agreement storage agreement = agreements[agreementId];
        Offer storage offer = agreement.currentOffer;

        require(offer.active, "No active offer.");
        require(block.timestamp <= offer.expiry, "Offer has expired.");
        require(msg.value == offer.tokenAmount * offer.price, "Incorrect ETH amount sent.");
        require(msg.sender == agreement.party1 || msg.sender == agreement.party2, "Not a party to this agreement.");

        IERC20(offer.token).transferFrom(offer.offeror, msg.sender, offer.tokenAmount);
        payable(offer.offeror).transfer(msg.value);
        payable(msg.sender).transfer(offer.tokenAmount * offer.price);

        offer.active = false;
        offer.staked = false;
        emit EventsLib.CounterOfferMade(agreementId, msg.sender);
    }

    function expireOffer(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        Offer storage offer = agreement.currentOffer;

        require(offer.active, "No active offer.");
        require(block.timestamp > offer.expiry, "Offer has not expired yet.");

        offer.active = false;
        emit EventsLib.OfferExpired(agreementId);
    }

    // Withdraw funds from contract
    function withdraw(uint256 amount) external {
        payable(msg.sender).transfer(amount);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
