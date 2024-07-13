// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Shotgun is Ownable {
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
    function withdraw(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
