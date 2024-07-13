// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract AgreementStorage {
    struct Offer {
        address token;
        uint256 price;
        uint256 tokenAmount;
        address offeror;
        uint256 expiry;
        bool active;
        bool staked;
    }

    struct Agreement {
        address party1;
        address party2;
        address token;
        uint256 duration;
        bool bound;
        bool party1Approved;
        bool party2Approved;
        Offer currentOffer;
    }

    mapping(uint256 => Agreement) public agreements;
    uint256 public agreementCounter;
}
