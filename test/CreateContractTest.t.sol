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

    function testCreateAgreement() public {}
}
