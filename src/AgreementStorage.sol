// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AgreementStorage {
    struct Agreement {
        address party1;
        address party2;
        address targetToken;
        address oracle;
        uint256 duration;
        bool bound;
        bool party1Approved;
        bool party2Approved;
        Offer currentOffer;
    }

    struct Offer {
        address targetToken;
        address paymentToken;
        uint256 price;
        uint256 targetTokenAmount;
        address offeror;
        uint256 expiry;
        bool active;
        bool staked;
    }

    mapping(uint256 => Agreement) public agreements;
    uint256 public agreementCounter;
}
