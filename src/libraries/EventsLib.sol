// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library EventsLib {
    event AgreementCreated(
        uint256 agreementId, address indexed party1, address indexed party2, address token, uint256 duration
    );
    event AgreementBound(uint256 agreementId);
    event OfferMade(
        uint256 agreementId, address indexed offeror, address token, uint256 price, uint256 shares, uint256 expiry
    );
    event OfferAccepted(uint256 agreementId, address indexed offeree);
    event CounterOfferMade(uint256 agreementId, address indexed counterOfferor);
    event OfferExpired(uint256 agreementId);
}
