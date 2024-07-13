// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AgreementStorage} from "./AgreementStorage.sol";
import {EventsLib} from "./libraries/EventsLib.sol";

contract Shotgun is AgreementStorage {
    using EventsLib for *;

    function createAgreement(address _party1, address _party2, address _targetToken, uint256 _duration)
        external
        returns (uint256)
    {
        agreementCounter++;
        agreements[agreementCounter] = Agreement({
            party1: _party1,
            party2: _party2,
            targetToken: _targetToken,
            duration: _duration,
            bound: false,
            party1Approved: false,
            party2Approved: false,
            currentOffer: Offer({
                targetToken: _targetToken,
                paymentToken: address(0),
                price: 0,
                targetTokenAmount: 0,
                offeror: address(0),
                expiry: 0,
                active: false,
                staked: false
            })
        });

        emit EventsLib.AgreementCreated(agreementCounter, _party1, _party2, _targetToken, _duration);
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

    function makeOffer(uint256 agreementId, address paymentToken, uint256 price, uint256 targetTokenAmount) external {
        Agreement storage agreement = agreements[agreementId];
        require(agreement.bound, "Agreement not bound.");
        require(!agreement.currentOffer.active, "An offer is already active.");
        require(msg.sender == agreement.party1 || msg.sender == agreement.party2, "Not a party to this agreement.");
        require(
            IERC20(agreement.targetToken).balanceOf(msg.sender) >= targetTokenAmount,
            "Insufficient target tokens to make offer."
        );
        require(
            IERC20(paymentToken).balanceOf(msg.sender) >= targetTokenAmount * price / 10 ** 18,
            "Insufficient payment tokens to make offer."
        );

        IERC20(paymentToken).transferFrom(msg.sender, address(this), targetTokenAmount * price / 10 ** 18);

        agreement.currentOffer = Offer({
            targetToken: agreement.targetToken,
            paymentToken: paymentToken,
            price: price,
            targetTokenAmount: targetTokenAmount,
            offeror: msg.sender,
            expiry: block.timestamp + agreement.duration,
            active: true,
            staked: true
        });

        emit EventsLib.OfferMade(
            agreementId, msg.sender, agreement.targetToken, price, targetTokenAmount, agreement.currentOffer.expiry
        );
    }

    function acceptOffer(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        Offer storage offer = agreement.currentOffer;

        require(offer.active, "No active offer.");
        require(block.timestamp <= offer.expiry, "Offer has expired.");
        require(
            IERC20(offer.targetToken).balanceOf(msg.sender) >= offer.targetTokenAmount,
            "Insufficient target tokens to accept offer."
        );
        require(msg.sender == agreement.party1 || msg.sender == agreement.party2, "Not a party to this agreement.");

        IERC20(offer.targetToken).transferFrom(msg.sender, offer.offeror, offer.targetTokenAmount);
        IERC20(offer.paymentToken).transfer(msg.sender, offer.targetTokenAmount * offer.price);

        offer.active = false;
        offer.staked = false;
        emit EventsLib.OfferAccepted(agreementId, msg.sender);
    }

    function counterOffer(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        Offer storage offer = agreement.currentOffer;

        require(offer.active, "No active offer.");
        require(block.timestamp <= offer.expiry, "Offer has expired.");
        require(
            IERC20(offer.paymentToken).balanceOf(msg.sender) >= offer.targetTokenAmount * offer.price,
            "Insufficient payment tokens to counter offer."
        );
        require(msg.sender == agreement.party1 || msg.sender == agreement.party2, "Not a party to this agreement.");

        IERC20(offer.paymentToken).transferFrom(msg.sender, offer.offeror, offer.targetTokenAmount * offer.price);
        IERC20(offer.targetToken).transferFrom(offer.offeror, msg.sender, offer.targetTokenAmount);

        offer.active = false;
        offer.staked = false;
        emit EventsLib.CounterOfferMade(agreementId, msg.sender);
    }

    function expireOffer(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        Offer storage offer = agreement.currentOffer;

        require(offer.active, "No active offer.");
        require(block.timestamp > offer.expiry, "Offer has not expired yet.");

        IERC20(offer.paymentToken).transfer(offer.offeror, offer.targetTokenAmount * offer.price);

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
