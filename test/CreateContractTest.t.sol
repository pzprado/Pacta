// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Shotgun.sol";

contract CreateContractTest is Test {
    Shotgun shotgun;
    address party1 = address(0x1);
    address party2 = address(0x2);
    address token = address(0x3);
    uint256 duration = 7 days;

    function setUp() public {
        shotgun = new Shotgun();
    }

    function testCreateAgreement() public {
        uint256 initialAgreementCounter = shotgun.agreementCounter();

        // Create an agreement
        uint256 agreementId = shotgun.createAgreement(party1, party2, token, duration);

        // Validate that the agreement counter has increased
        uint256 newAgreementCounter = shotgun.agreementCounter();
        assertEq(newAgreementCounter, initialAgreementCounter + 1);

        // Validate the agreement details
        (address _party1, address _party2, address _token, uint256 _duration,,,,) = shotgun.agreements(agreementId);

        assertEq(_party1, party1);
        assertEq(_party2, party2);
        assertEq(_token, token);
        assertEq(_duration, duration);
        console.log("duration: %s", duration);
    }
}
