// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Shotgun.sol";
import "./mock/MockERC20.sol";

contract ShotgunTest is Test {
    Shotgun shotgun;
    MockERC20 targetToken;
    MockERC20 paymentToken;
    address party1 = address(0x1);
    address party2 = address(0x2);
    address thirdParty = address(0x3);
    uint256 duration = 7 days;
    uint256 initialSupply = 1000 * 10 ** 18; // Adjust according to decimals

    function setUp() public {
        shotgun = new Shotgun();
        targetToken = new MockERC20("MockToken", "MTK");
        paymentToken = new MockERC20("Wrapped ETH", "WETH");
        targetToken.mint(party1, initialSupply);
        targetToken.mint(party2, initialSupply);
        paymentToken.mint(party1, initialSupply);
        paymentToken.mint(party2, initialSupply);
    }

    function testCreateAgreement() public {
        uint256 initialAgreementCounter = shotgun.agreementCounter();

        // Create an agreement
        uint256 agreementId = shotgun.createAgreement(party1, party2, address(targetToken), duration);

        // Validate that the agreement counter has increased
        uint256 newAgreementCounter = shotgun.agreementCounter();
        assertEq(newAgreementCounter, initialAgreementCounter + 1);

        // Validate the agreement details
        (
            address _party1,
            address _party2,
            address _targetToken,
            uint256 _duration,
            ,
            ,
            ,
            Shotgun.Offer memory currentOffer
        ) = shotgun.agreements(agreementId);

        assertEq(_party1, party1);
        assertEq(_party2, party2);
        assertEq(_targetToken, address(targetToken));
        assertEq(_duration, duration);
    }

    function testMakeOffer() public {
        uint256 agreementId = shotgun.createAgreement(party1, party2, address(targetToken), duration);

        // Approve the spending from both parties
        vm.prank(party1);
        targetToken.approve(address(shotgun), type(uint256).max);
        vm.prank(party2);
        targetToken.approve(address(shotgun), type(uint256).max);

        // Approve the agreement from both parties
        vm.prank(party1);
        shotgun.approveAgreement(agreementId);
        vm.prank(party2);
        shotgun.approveAgreement(agreementId);

        // Verify the agreement is bound
        (,,,, bool bound,,,) = shotgun.agreements(agreementId);
        console.log("Agreement bound status: %s", bound);
        assert(bound == true);

        // Ensure sufficient balance and approval for paymentToken
        uint256 targetTokenAmount = 100 * 10 ** 18; // Adjust according to decimals
        uint256 price = 1 * 10 ** 18; // paymentToken has 18 decimals

        // Approve the Shotgun contract to spend party1's target tokens and payment tokens
        vm.prank(party1);
        targetToken.approve(address(shotgun), targetTokenAmount);
        vm.prank(party1);
        paymentToken.approve(address(shotgun), targetTokenAmount * price / 10 ** 18);

        // Check balances and approvals for debugging
        uint256 targetTokenBalance = targetToken.balanceOf(party1);
        uint256 targetTokenAllowance = targetToken.allowance(party1, address(shotgun));
        uint256 paymentTokenBalance = paymentToken.balanceOf(party1);
        uint256 paymentTokenAllowance = paymentToken.allowance(party1, address(shotgun));

        console.log("Target Token Balance: %s", targetTokenBalance);
        console.log("Target Token Allowance: %s", targetTokenAllowance);
        console.log("Payment Token Balance: %s", paymentTokenBalance);
        console.log("Payment Token Allowance: %s", paymentTokenAllowance);

        assert(targetTokenBalance >= targetTokenAmount);
        assert(targetTokenAllowance >= targetTokenAmount);
        assert(paymentTokenBalance >= targetTokenAmount * price / 10 ** 18);
        assert(paymentTokenAllowance >= targetTokenAmount * price / 10 ** 18);

        // Check initial Shotgun contract balance for paymentToken
        uint256 initialShotgunBalance = paymentToken.balanceOf(address(shotgun));
        console.log("Initial Shotgun Payment Token Balance: %s", initialShotgunBalance);

        // Make an offer
        vm.prank(party1);
        shotgun.makeOffer(agreementId, address(paymentToken), price, targetTokenAmount);

        // Validate the offer details
        (,,,,,,, Shotgun.Offer memory currentOffer) = shotgun.agreements(agreementId);
        assertEq(currentOffer.targetToken, address(targetToken));
        assertEq(currentOffer.paymentToken, address(paymentToken));
        assertEq(currentOffer.price, price);
        assertEq(currentOffer.targetTokenAmount, targetTokenAmount);
        assertEq(currentOffer.offeror, party1);
        assert(currentOffer.active == true);
        assert(currentOffer.staked == true);

        // Check Shotgun contract balance for paymentToken after the offer is made
        uint256 finalShotgunBalance = paymentToken.balanceOf(address(shotgun));
        console.log("Final Shotgun Payment Token Balance: %s", finalShotgunBalance);

        assertEq(finalShotgunBalance, initialShotgunBalance + (targetTokenAmount * price / 10 ** 18));
    }

    function testExpireOffer() public {
        uint256 agreementId = shotgun.createAgreement(party1, party2, address(targetToken), 1 days);

        // Approve the spending from both parties
        vm.prank(party1);
        targetToken.approve(address(shotgun), type(uint256).max);
        vm.prank(party2);
        targetToken.approve(address(shotgun), type(uint256).max);

        // Approve the agreement from both parties
        vm.prank(party1);
        shotgun.approveAgreement(agreementId);
        vm.prank(party2);
        shotgun.approveAgreement(agreementId);

        // Verify the agreement is bound
        (,,,, bool bound,,,) = shotgun.agreements(agreementId);
        assert(bound == true);

        // Ensure sufficient balance and approval for paymentToken
        uint256 targetTokenAmount = 100 * 10 ** 18; // Adjust according to decimals
        uint256 price = 1 * 10 ** 18; // paymentToken has 18 decimals

        // Approve the Shotgun contract to spend party1's target tokens and payment tokens
        vm.prank(party1);
        targetToken.approve(address(shotgun), targetTokenAmount);
        vm.prank(party1);
        paymentToken.approve(address(shotgun), targetTokenAmount * price / 10 ** 18);

        // Party2 approves the Shotgun contract to spend their target tokens
        vm.prank(party2);
        targetToken.approve(address(shotgun), targetTokenAmount);

        // Make an offer
        vm.prank(party1);
        shotgun.makeOffer(agreementId, address(paymentToken), price, targetTokenAmount);

        // Validate the offer details
        (,,,,,,, Shotgun.Offer memory currentOffer) = shotgun.agreements(agreementId);
        assertEq(currentOffer.targetToken, address(targetToken));
        assertEq(currentOffer.paymentToken, address(paymentToken));
        assertEq(currentOffer.price, price);
        assertEq(currentOffer.targetTokenAmount, targetTokenAmount);
        assertEq(currentOffer.offeror, party1);
        assert(currentOffer.active == true);
        assert(currentOffer.staked == true);

        // Check initial balances of parties and contract
        uint256 initialParty1TargetBalance = targetToken.balanceOf(party1);
        uint256 initialParty2PaymentBalance = paymentToken.balanceOf(party2);
        uint256 initialShotgunPaymentBalance = paymentToken.balanceOf(address(shotgun));

        console.log("Initial Party1 Target Token Balance: %s", initialParty1TargetBalance);
        console.log("Initial Party2 Payment Token Balance: %s", initialParty2PaymentBalance);
        console.log("Initial Shotgun Payment Token Balance: %s", initialShotgunPaymentBalance);

        // Simulate the passage of time to expire the offer
        vm.warp(block.timestamp + 2 days);

        // Execute the expireOffer function
        vm.prank(thirdParty); // Anyone can call this function
        shotgun.expireOffer(agreementId);

        // Validate the offer has expired and the tokens have been transferred
        (,,,,,,, currentOffer) = shotgun.agreements(agreementId);
        assert(currentOffer.active == false);

        uint256 finalParty1TargetBalance = targetToken.balanceOf(party1);
        uint256 finalParty2PaymentBalance = paymentToken.balanceOf(party2);
        uint256 finalShotgunPaymentBalance = paymentToken.balanceOf(address(shotgun));

        console.log("Final Party1 Target Token Balance: %s", finalParty1TargetBalance);
        console.log("Final Party2 Payment Token Balance: %s", finalParty2PaymentBalance);
        console.log("Final Shotgun Payment Token Balance: %s", finalShotgunPaymentBalance);

        assertEq(finalParty1TargetBalance, initialParty1TargetBalance + targetTokenAmount); // party1's target tokens should be transferred
        assertEq(finalParty2PaymentBalance, initialParty2PaymentBalance + (targetTokenAmount * price / 10 ** 18)); // party2 should receive the staked payment tokens
        assertEq(finalShotgunPaymentBalance, initialShotgunPaymentBalance - (targetTokenAmount * price / 10 ** 18)); // Shotgun contract balance should decrease
    }
}
