// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AgreementStorage {
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

    struct Agreement {
        address party1;
        address party2;
        address targetToken;
        uint256 duration;
        bool bound;
        bool party1Approved;
        bool party2Approved;
        Offer currentOffer;
    }

    mapping(uint256 => Agreement) public agreements;
    uint256 public agreementCounter;
}
