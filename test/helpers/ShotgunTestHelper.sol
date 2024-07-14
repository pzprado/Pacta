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
    address oracle = 0xdD7c06561689c73f0A67F2179e273cCF45EFc964; // ARB oracle
    address selfKisser = 0xc0fe3a070Bc98b4a45d735A52a1AFDd134E0283f;
    uint256 duration = 7 days;
    uint256 initialSupply = 1000 * 10 ** 18; // Adjust according to decimals

    function setUp() public {
        uint256 arbFork = vm.createFork(vm.envString("ARBITRUM_SEPOLIA_RPC_URL"), 63683874);
        vm.selectFork(arbFork);
        console.log("Fork created at block %s", block.number);

        shotgun = new Shotgun(selfKisser);
        targetToken = new MockERC20("MockToken", "MTK");
        paymentToken = new MockERC20("Wrapped ETH", "WETH");
        targetToken.mint(partyA, initialSupply);
        targetToken.mint(partyB, initialSupply);
        paymentToken.mint(partyA, initialSupply);
        paymentToken.mint(partyB, initialSupply);
        vm.deal(partyA, initialSupply / 5);
        vm.deal(partyB, initialSupply / 5);
        deal(address(targetToken), partyA, initialSupply);
        deal(address(targetToken), partyB, initialSupply);
        deal(address(paymentToken), partyA, initialSupply);
        deal(address(paymentToken), partyB, initialSupply);
        console.log("Setup complete");
    }

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
        uint256 agreementId = shotgun.createAgreement(partyB, address(targetToken), oracle, duration);

        approveTokens(partyA, type(uint256).max, type(uint256).max);
        approveTokens(partyB, type(uint256).max, type(uint256).max);

        approveAgreement(agreementId, partyA);
        approveAgreement(agreementId, partyB);

        return agreementId;
    }

    function logBalances(string memory prefix) internal {
        console.log("%s Balances", prefix);
        console.log("Category                 | PartyA                   | PartyB");
        console.log("-------------------------|--------------------------|--------------------------");
        console.log(
            "Target Token             | %s                     | %s   ",
            targetToken.balanceOf(partyA) / 1e18,
            targetToken.balanceOf(partyB) / 1e18
        );
        console.log(
            "WETH (Payment Token)     | %s                     | %s   ",
            paymentToken.balanceOf(partyA) / 1e18,
            paymentToken.balanceOf(partyB) / 1e18
        );
        console.log("===============================================================================");
        console.log("                                                                              ");
        console.log("                                                                              ");
    }

    function logMakeOfferBalances(string memory prefix) internal {
        uint256 targetTokenBalanceA = targetToken.balanceOf(partyA);
        uint256 targetTokenAllowanceA = targetToken.allowance(partyA, address(shotgun));
        uint256 paymentTokenBalanceA = paymentToken.balanceOf(partyA);
        uint256 paymentTokenAllowanceA = paymentToken.allowance(partyA, address(shotgun));

        console.log("-------------------------------------------------------------------------------");
        console.log("%s Balances and Allowances", prefix);
        console.log("Category                  | PartyA       ");
        console.log("--------------------------|----------------------------------------------------");
        console.log("Target Token Balance      | %s", targetTokenBalanceA / 1e18);
        console.log("Target Token Allowance    | %s", targetTokenAllowanceA / 1e18);
        console.log("WETH (Payment Token) Bal  | %s", paymentTokenBalanceA / 1e18);
        console.log("WETH (Payment Token) Allow| %s", paymentTokenAllowanceA / 1e18);

        // Check Shotgun contract balance for paymentToken
        console.log("Shotgun Payment Token Bal | %s", paymentToken.balanceOf(address(shotgun)) / 1e18);
        console.log("===============================================================================");
        console.log("                                                                              ");
        console.log("                                                                              ");
    }
}
