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
    }

    Offer public currentOffer;

    event OfferMade(address indexed offeror, address token, uint256 price, uint256 shares, uint256 expiry);
    event OfferAccepted(address indexed offeree);
    event CounterOfferMade(address indexed counterOfferor);
    event OfferExpired();

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
        // TODO: add logic
        emit OfferAccepted(msg.sender);
    }

    function counterOffer() external payable {
        // TODO: add logic
        emit OfferCountered(msg.sender);
    }

    function rejectOffer() external onlyOwner {
        // TODO: add logic
        emit OfferRejected(msg.sender);
    }
}
