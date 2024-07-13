// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Shotgun.sol";
import "../mock/MockERC20.sol";

contract ShotgunTestHelper is Test {
    Shotgun shotgun;
    MockERC20 targetToken;
    MockERC20 paymentToken;
    address partyA = address(0x1);
    address partyB = address(0x2);
    address thirdParty = address(0x3);
    uint256 duration = 7 days;
    uint256 initialSupply = 1000 * 10 ** 18; // Adjust according to decimals

    function approveTokens(address _party, uint256 _targetTokenAmount, uint256 _paymentTokenAmount) internal {
        vm.prank(_party);
        targetToken.approve(address(shotgun), _targetTokenAmount);
        vm.prank(_party);
        paymentToken.approve(address(shotgun), _paymentTokenAmount);
    }

    function approveAgreement(uint256 agreementId, address _party) internal {
        vm.prank(_party);
        shotgun.approveAgreement(agreementId);
    }

    function createAndApproveAgreement() internal returns (uint256) {
        uint256 agreementId = shotgun.createAgreement(partyA, partyB, address(targetToken), duration);

        approveTokens(partyA, type(uint256).max, type(uint256).max);
        approveTokens(partyB, type(uint256).max, type(uint256).max);

        approveAgreement(agreementId, partyA);
        approveAgreement(agreementId, partyB);

        return agreementId;
    }

    function logBalances(string memory prefix) internal {
        console.log("%s PartyA Target Token Balance: %s", prefix, targetToken.balanceOf(partyA) / 1e18);
        console.log("%s PartyA WETH (Payment Token) Balance: %s", prefix, paymentToken.balanceOf(partyA) / 1e18);
        console.log("%s PartyB Target Token Balance: %s", prefix, targetToken.balanceOf(partyB) / 1e18);
        console.log("%s PartyB WETH (Payment Token) Balance: %s", prefix, paymentToken.balanceOf(partyB) / 1e18);
        console.log(
            "%s Shotgun WETH (Payment Token) Balance: %s", prefix, paymentToken.balanceOf(address(shotgun)) / 1e18
        );
    }
}
