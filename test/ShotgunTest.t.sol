// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./helpers/ShotgunTestHelper.sol";

contract ShotgunTest is ShotgunTestHelper {
    function setUp() public {
        shotgun = new Shotgun();
        targetToken = new MockERC20("MockToken", "MTK");
        paymentToken = new MockERC20("Wrapped ETH", "WETH");
        targetToken.mint(partyA, initialSupply);
        targetToken.mint(partyB, initialSupply);
        paymentToken.mint(partyA, initialSupply);
        paymentToken.mint(partyB, initialSupply);
    }

    function testA_CreateAgreement() public {
        uint256 initialAgreementCounter = shotgun.agreementCounter();

        // Create an agreement
        vm.prank(partyA);
        uint256 agreementId = shotgun.createAgreement(partyB, address(targetToken), oracle, duration);

        // Validate that the agreement counter has increased
        uint256 newAgreementCounter = shotgun.agreementCounter();
        assertEq(newAgreementCounter, initialAgreementCounter + 1);

        // Validate the agreement details
        (
            address _party1,
            address _party2,
            address _targetToken,
            ,
            uint256 _duration,
            ,
            ,
            ,
            Shotgun.Offer memory currentOffer
        ) = shotgun.agreements(agreementId);

        assertEq(_party1, partyA);
        assertEq(_party2, partyB);
        assertEq(_targetToken, address(targetToken));
        assertEq(_duration, duration);
    }

    function testB_MakeOffer() public {
        vm.prank(partyA);
        uint256 agreementId = createAndApproveAgreement();

        // Verify the agreement is bound
        (,,,,, bool bound,,,) = shotgun.agreements(agreementId);
        console.log("Agreement bound status: %s", bound);
        assert(bound == true);

        // Ensure sufficient balance and approval for paymentToken
        uint256 targetTokenAmount = targetToken.balanceOf(partyB); // Use total amount of target tokens held by partyB
        uint256 price = 1 * 10 ** 18; // paymentToken has 18 decimals

        logMakeOfferBalances("Initial");

        // Make an offer
        vm.prank(partyA);
        shotgun.makeOffer(agreementId, address(paymentToken), price, targetTokenAmount);

        logMakeOfferBalances("Final");

        // Validate the offer details
        (,,,,,,,, Shotgun.Offer memory currentOffer) = shotgun.agreements(agreementId);
        assertEq(currentOffer.targetToken, address(targetToken));
        assertEq(currentOffer.paymentToken, address(paymentToken));
        assertEq(currentOffer.price, price);
        assertEq(currentOffer.targetTokenAmount, targetTokenAmount);
        assertEq(currentOffer.offeror, partyA);
        assert(currentOffer.active == true);
        assert(currentOffer.staked == true);

        assertEq(paymentToken.balanceOf(address(shotgun)), targetTokenAmount * price / 10 ** 18);
    }

    function testC_ExpireOffer() public {
        vm.prank(partyA);
        uint256 agreementId = createAndApproveAgreement();

        // Ensure sufficient balance and approval for paymentToken
        uint256 targetTokenAmount = targetToken.balanceOf(partyB); // Use total amount of target tokens held by partyB
        uint256 price = 1 * 10 ** 18; // paymentToken has 18 decimals

        approveTokens(partyA, targetTokenAmount, targetTokenAmount * price / 10 ** 18);
        approveTokens(partyB, targetTokenAmount, 0);

        logBalances("Initial");

        // Make an offer
        vm.prank(partyA);
        shotgun.makeOffer(agreementId, address(paymentToken), price, targetTokenAmount);

        // Validate the offer details
        (,,,,,,,, Shotgun.Offer memory currentOffer) = shotgun.agreements(agreementId);
        assertEq(currentOffer.targetToken, address(targetToken));
        assertEq(currentOffer.paymentToken, address(paymentToken));
        assertEq(currentOffer.price, price);
        assertEq(currentOffer.targetTokenAmount, targetTokenAmount);
        assertEq(currentOffer.offeror, partyA);
        assert(currentOffer.active == true);
        assert(currentOffer.staked == true);

        // Simulate the passage of time to expire the offer
        vm.warp(block.timestamp + duration + 1); // Warp time by the duration of the agreement plus 1 second

        // Execute the expireOffer function
        vm.prank(thirdParty); // Anyone can call this function
        shotgun.expireOffer(agreementId);

        // Validate the offer has expired and the tokens have been transferred
        (,,,,,,,, currentOffer) = shotgun.agreements(agreementId);
        assert(currentOffer.active == false);

        logBalances("Final");

        uint256 finalTargetTokenBalanceA = targetToken.balanceOf(partyA);
        uint256 finalPaymentTokenBalanceB = paymentToken.balanceOf(partyB);

        assertEq(finalTargetTokenBalanceA, initialSupply + targetTokenAmount); // partyA's target tokens should be transferred
        assertEq(finalPaymentTokenBalanceB, initialSupply * 2); // partyB should receive the staked payment tokens
        assertEq(paymentToken.balanceOf(address(shotgun)), 0); // Shotgun contract balance should decrease
    }

    function testD_CounterOffer() public {
        vm.prank(partyA);
        uint256 agreementId = createAndApproveAgreement();

        logBalances("Initial");

        // Ensure sufficient balance and approval for paymentToken
        uint256 targetTokenAmount = targetToken.balanceOf(partyB); // Use total amount of target tokens held by partyB
        uint256 price = 1 * 10 ** 18; // paymentToken has 18 decimals

        approveTokens(partyA, targetTokenAmount, targetTokenAmount * price / 10 ** 18);
        approveTokens(partyB, 0, targetTokenAmount * price / 10 ** 18);

        // Make an offer
        vm.prank(partyA);
        shotgun.makeOffer(agreementId, address(paymentToken), price, targetTokenAmount);

        // Validate the offer details
        (,,,,,,,, Shotgun.Offer memory currentOffer) = shotgun.agreements(agreementId);
        assertEq(currentOffer.targetToken, address(targetToken));
        assertEq(currentOffer.paymentToken, address(paymentToken));
        assertEq(currentOffer.price, price);
        assertEq(currentOffer.targetTokenAmount, targetTokenAmount);
        assertEq(currentOffer.offeror, partyA);
        assert(currentOffer.active == true);
        assert(currentOffer.staked == true);

        // Execute the counterOffer function by partyB
        vm.prank(partyB);
        shotgun.counterOffer(agreementId);

        // Validate the counter offer has been accepted and the tokens have been transferred
        (,,,,,,,, currentOffer) = shotgun.agreements(agreementId);
        assert(currentOffer.active == false);

        logBalances("Final");

        uint256 finalTargetTokenBalanceA = targetToken.balanceOf(partyA);
        uint256 finalPaymentTokenBalanceA = paymentToken.balanceOf(partyA);
        uint256 finalTargetTokenBalanceB = targetToken.balanceOf(partyB);
        uint256 finalPaymentTokenBalanceB = paymentToken.balanceOf(partyB);

        assertEq(finalTargetTokenBalanceA, 0); // partyA's target tokens should be transferred to partyB
        assertEq(finalPaymentTokenBalanceA, initialSupply * 2); // partyA should receive their staked payment tokens back
        assertEq(finalPaymentTokenBalanceB, 0); // partyB should spend their payment tokens
        assertEq(finalTargetTokenBalanceB, initialSupply * 2); // partyB should receive target tokens from partyA
        assertEq(paymentToken.balanceOf(address(shotgun)), 0); // Shotgun contract balance should remain the same
    }
}
