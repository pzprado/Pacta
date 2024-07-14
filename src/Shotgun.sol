// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AgreementStorage} from "./AgreementStorage.sol";
import {EventsLib} from "./libraries/EventsLib.sol";
import {IChronicle, ISelfKisser} from "./interfaces/IChronicle.sol";

/// @title Shotgun Contract for Institutional Shareholders Agreements
/// @notice This contract allows parties to create, approve, and manage shotgun agreements onchain
contract Shotgun is AgreementStorage {
    using EventsLib for *;

    ISelfKisser public selfKisser;

    /// @notice Constructor to set the SelfKisser contract address
    /// @param _selfKisser Address of the SelfKisser contract
    constructor(address _selfKisser) {
        selfKisser = ISelfKisser(_selfKisser);
    }

    /// @notice Create a new agreement
    /// @param _party2 Address of the second party in the agreement
    /// @param _targetToken Address of the target token
    /// @param _oracle Address of the oracle for price data
    /// @param _duration Duration of the agreement
    /// @return agreementId The ID of the newly created agreement
    function createAgreement(address _party2, address _targetToken, address _oracle, uint256 _duration)
        external
        returns (uint256)
    {
        // Whitelist the Shotgun contract with the given oracle
        selfKisser.selfKiss(_oracle);

        agreementCounter++;
        agreements[agreementCounter] = Agreement({
            party1: msg.sender,
            party2: _party2,
            targetToken: _targetToken,
            oracle: _oracle,
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

        emit EventsLib.AgreementCreated(agreementCounter, msg.sender, _party2, _targetToken, _duration);
        return agreementCounter;
    }

    /// @notice Approve an agreement by either party
    /// @param agreementId ID of the agreement to be approved
    function approveAgreement(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        require(msg.sender == agreement.party1 || msg.sender == agreement.party2, "Not a party to this agreement.");
        require(!agreement.bound, "Agreement already bound.");

        if (msg.sender == agreement.party1) {
            require(
                IERC20(agreement.targetToken).allowance(agreement.party1, address(this)) == type(uint256).max,
                "Party1 must approve max spending."
            );
            agreement.party1Approved = true;
        } else if (msg.sender == agreement.party2) {
            require(
                IERC20(agreement.targetToken).allowance(agreement.party2, address(this)) == type(uint256).max,
                "Party2 must approve max spending."
            );
            agreement.party2Approved = true;
        }

        if (agreement.party1Approved && agreement.party2Approved) {
            agreement.bound = true;
            emit EventsLib.AgreementBound(agreementId);
        }
    }

    /// @notice Make an offer for an agreement
    /// @param agreementId ID of the agreement
    /// @param paymentToken Address of the payment token
    /// @param price Price of the target tokens in payment tokens
    /// @param targetTokenAmount Amount of target tokens
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

    /// @notice Accept an active offer
    /// @param agreementId ID of the agreement
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
        IERC20(offer.paymentToken).transfer(msg.sender, offer.targetTokenAmount * offer.price / 10 ** 18);

        offer.active = false;
        offer.staked = false;
        emit EventsLib.OfferAccepted(agreementId, msg.sender);
    }

    /// @notice Make a counter offer to an active offer
    /// @param agreementId ID of the agreement
    function counterOffer(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        Offer storage offer = agreement.currentOffer;

        require(offer.active, "No active offer.");
        require(block.timestamp <= offer.expiry, "Offer has expired.");
        require(
            IERC20(offer.paymentToken).balanceOf(msg.sender) >= offer.targetTokenAmount * offer.price / 10 ** 18,
            "Insufficient payment tokens to counter offer."
        );
        require(msg.sender == agreement.party1 || msg.sender == agreement.party2, "Not a party to this agreement.");

        IERC20(offer.paymentToken).transferFrom(
            msg.sender, offer.offeror, offer.targetTokenAmount * offer.price / 10 ** 18
        );
        IERC20(offer.targetToken).transferFrom(offer.offeror, msg.sender, offer.targetTokenAmount);

        // Return the staked payment token to the original offeror
        IERC20(offer.paymentToken).transfer(offer.offeror, offer.targetTokenAmount * offer.price / 10 ** 18);

        offer.active = false;
        offer.staked = false;
        emit EventsLib.CounterOfferMade(agreementId, msg.sender);
    }

    /// @notice Expire an offer that has passed its expiry time
    /// @param agreementId ID of the agreement
    function expireOffer(uint256 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        Offer storage offer = agreement.currentOffer;

        require(offer.active, "No active offer.");
        require(block.timestamp > offer.expiry, "Offer has not expired yet.");

        // Transfer the staked payment token to the offeree
        IERC20(offer.paymentToken).transfer(agreement.party2, offer.targetTokenAmount * offer.price / 10 ** 18);

        // Transfer the target token from the offeree to the offeror
        IERC20(offer.targetToken).transferFrom(agreement.party2, offer.offeror, offer.targetTokenAmount);

        offer.active = false;
        emit EventsLib.OfferExpired(agreementId);
    }

    /// @notice Get the valuation of an active offer using the oracle
    /// @param agreementId ID of the agreement
    /// @return offerPrice The price of the offer
    /// @return oraclePrice The price from the oracle
    function getOfferValuation(uint256 agreementId) public view returns (uint256 offerPrice, uint256 oraclePrice) {
        Agreement storage agreement = agreements[agreementId];
        Offer storage offer = agreement.currentOffer;

        require(offer.active, "No active offer.");

        (uint256 oracleValue,) = IChronicle(agreement.oracle).readWithAge();

        return (offer.price, oracleValue);
    }

    /// @notice Fallback function to receive Ether
    receive() external payable {}
}
