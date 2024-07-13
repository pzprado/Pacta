// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Shotgun is Ownable {
    IERC20 public shareToken;
    uint256 public offerPrice;
    address public offeror;
    uint256 public offerExpiry;
    bool public offerAccepted;
    uint256 public sharesAmount;

    event OfferMade(address indexed offeror, uint256 price, uint256 sharesAmount, uint256 expiry);
    event OfferAccepted(address indexed acceptor);
    event OfferCountered(address indexed counterOfferor);
    event OfferRejected(address indexed rejector);

    constructor(address _shareToken) {
        shareToken = IERC20(_shareToken);
    }

    function makeOffer(uint256 price, uint256 shares, uint256 duration) external {
        // TODO: add logic
        emit OfferMade(msg.sender, price, shares, offerExpiry);
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
