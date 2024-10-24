# Bitcoin-Backed NFT Marketplace with DeFi Elements

A decentralized NFT marketplace smart contract built on Stacks, featuring NFT minting with Bitcoin collateralization, fractional ownership, staking capabilities, and DeFi elements.

## Features

### Core NFT Functionality

- Mint NFTs with Bitcoin (STX) collateral backing
- Transfer NFTs between wallets
- Minimum collateral ratio of 150% required for minting
- URI validation for NFT metadata

### Marketplace

- List NFTs for sale with custom pricing
- Purchase NFTs with automatic fee distribution
- 2.5% protocol fee on all transactions
- Built-in overflow protection for mathematical operations

### Fractional Ownership

- Split NFT ownership into transferable shares
- Track share distribution across multiple owners
- Transfer shares between wallets with balance validation

### Staking Mechanism

- Stake NFTs to earn yield
- 5% annual yield rate
- Accumulated rewards calculation based on block height
- Claim rewards in STX tokens
- Unstake with automatic reward distribution

## Technical Details

### Constants

```clarity
min-collateral-ratio: 150%
protocol-fee: 2.5% (25 basis points)
yield-rate: 5% annually (50 basis points)
```

### Error Codes

- `u100`: Owner-only operation
- `u101`: Not token owner
- `u102`: Insufficient balance
- `u103`: Invalid token
- `u104`: Listing not found
- `u105`: Invalid price
- `u106`: Insufficient collateral
- `u107`: Already staked
- `u108`: Not staked
- `u109`: Invalid percentage
- `u110`: Invalid URI
- `u111`: Invalid recipient
- `u112`: Overflow error

## Usage

### Minting an NFT

```clarity
(contract-call? .nft-marketplace mint-nft "https://example.com/metadata.json" u1000)
```

### Listing an NFT

```clarity
(contract-call? .nft-marketplace list-nft u1 u5000)
```

### Purchasing an NFT

```clarity
(contract-call? .nft-marketplace purchase-nft u1)
```

### Staking Operations

```clarity
;; Stake NFT
(contract-call? .nft-marketplace stake-nft u1)

;; Unstake NFT
(contract-call? .nft-marketplace unstake-nft u1)
```

### Fractional Ownership

```clarity
(contract-call? .nft-marketplace transfer-shares u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u50)
```

## Security Considerations

1. **Collateral Protection**

   - All NFTs must maintain minimum collateral ratio
   - Collateral is locked in contract until NFT is burned or transferred

2. **Access Control**

   - Owner-only functions for critical operations
   - Token ownership verification for transfers and listings
   - Contract self-calls prevented for sensitive operations

3. **Mathematical Safety**
   - Overflow checking on all mathematical operations
   - Safe addition implementation for balance updates
   - Percentage calculations use basis points for precision

## Query Functions

### Read-Only Operations

- `get-token-info`: Retrieve token details
- `get-listing`: Get active listing information
- `get-fractional-shares`: Query share ownership
- `get-staking-rewards`: Check accumulated rewards
- `calculate-rewards`: Preview pending staking rewards

## Development

### Prerequisites

- Clarity contract deployment environment
- Access to Stacks blockchain
- Understanding of Bitcoin and STX token mechanics

### Testing

Recommended test coverage should include:

- NFT minting with various collateral ratios
- Marketplace operations with edge cases
- Staking reward calculations
- Fractional ownership transfers
- Error condition handling

## License

This smart contract is provided underunder the MIT License. See the [LICENSE](LICENSE) file for details.

---

Note: This is a complex smart contract handling real value. Thorough audit and testing are strongly recommended before mainnet deployment.
