# BitStack Lending Protocol

A decentralized lending protocol on the Stacks blockchain that enables STX token lending using Bitcoin as collateral, leveraging Stacks' unique Bitcoin connection for secure cross-chain operations.

## 🌟 Overview

BitStack Lending Protocol bridges Bitcoin and Stacks ecosystems by allowing users to:
- Deposit Bitcoin as collateral
- Borrow STX tokens against their Bitcoin holdings
- Earn yield on STX deposits
- Maintain exposure to Bitcoin while accessing DeFi liquidity

## 🏗️ Architecture

### Core Components

- **Smart Contract**: Written in Clarity, deployed on Stacks blockchain
- **Bitcoin Integration**: Leverages Stacks' native Bitcoin connectivity
- **Price Oracle**: Real-time BTC/STX price feeds for accurate collateralization
- **Liquidation Engine**: Automated liquidation of undercollateralized positions

### Key Features

- **Over-collateralized Loans**: 150% collateralization ratio ensures protocol security
- **Competitive Interest Rates**: 5% annual interest rate on STX loans
- **Flexible Loan Terms**: 1-year loan duration with early repayment options
- **Automated Liquidations**: Protection against market volatility
- **Multi-user Support**: Each user can manage up to 50 concurrent loans

## 📋 Prerequisites

- Node.js v16+ and npm/yarn
- Clarinet CLI tool for Clarity development
- Stacks Wallet for testnet/mainnet interaction
- Basic understanding of Bitcoin and Stacks ecosystems

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/bitstack-lending.git
cd bitstack-lending
```

### 2. Install Dependencies

```bash
npm install
# or
yarn install
```

### 3. Install Clarinet

```bash
curl -L https://github.com/hirosystems/clarinet/releases/download/v1.8.0/clarinet-linux-x64.tar.gz -o clarinet.tar.gz
tar -xzf clarinet.tar.gz
sudo mv clarinet /usr/local/bin/
```

### 4. Initialize Clarinet Project

```bash
clarinet new bitstack-lending
cd bitstack-lending
```

## 📝 Contract Deployment

### Testnet Deployment

1. Configure your `Clarinet.toml`:

```toml
[project]
name = "bitstack-lending"
description = "Bitcoin-collateralized STX lending protocol"
authors = ["Your Name <email@example.com>"]
telemetry = true
cache_dir = "./.cache"
requirements = []

[contracts.bitstack-lending]
path = "contracts/bitstack-lending.clar"
depends_on = []

[[project.requirements]]
contract_id = "SP000000000000000000002Q6VF78.pox-4"

[repl.analysis]
passes = ["check_checker"]

[repl.analysis.check_checker]
strict = false
trusted_sender = false
trusted_caller = false
callee_filter = false
```

2. Deploy to testnet:

```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## 🔧 Usage

### For Borrowers

#### 1. Deposit Bitcoin Collateral

```clarity
;; Deposit 1 BTC (100,000,000 satoshis) as collateral
(contract-call? .bitstack-lending deposit-btc-collateral u100000000)
```

#### 2. Create a Loan

```clarity
;; Borrow 1000 STX against 0.5 BTC collateral
(contract-call? .bitstack-lending create-loan u1000000000 u50000000)
```

#### 3. Repay Loan

```clarity
;; Repay loan with ID 1
(contract-call? .bitstack-lending repay-loan u1)
```

#### 4. Withdraw Unused Collateral

```clarity
;; Withdraw 0.1 BTC from available collateral
(contract-call? .bitstack-lending withdraw-btc-collateral u10000000)
```

### For Lenders/Liquidity Providers

#### Add STX Liquidity (Admin Only)

```clarity
;; Add 10,000 STX to lending pool
(contract-call? .bitstack-lending add-liquidity u10000000000)
```

### Read-Only Functions

#### Check Loan Status

```clarity
;; Get detailed loan information
(contract-call? .bitstack-lending get-loan-status u1)
```

#### View User Loans

```clarity
;; Get all loan IDs for a user
(contract-call? .bitstack-lending get-user-loans 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX975CN7QCR)
```

#### Calculate Required Collateral

```clarity
;; Calculate BTC needed for 1000 STX loan
(contract-call? .bitstack-lending calculate-required-collateral u1000000000)
```

## 🔐 Security Features

### Collateralization Requirements

- **Minimum Ratio**: 150% (adjustable by governance)
- **Liquidation Threshold**: Below 150% collateral ratio
- **Grace Period**: Loans can be liquidated after expiration

### Access Controls

- **Owner Functions**: Price updates, liquidity management, emergency controls
- **Authorized Callers**: Configurable permission system
- **User Isolation**: Individual collateral and loan tracking

### Risk Management

- **Price Oracle Integration**: Real-time BTC/STX price feeds
- **Automated Liquidations**: Protection against market volatility
- **Interest Accrual**: Time-based interest calculation
- **Maximum Loan Limits**: Per-user loan count restrictions

## 📊 Contract Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `LIQUIDATION_RATIO` | 150% | Minimum collateralization ratio |
| `INTEREST_RATE` | 5% | Annual interest rate |
| `LOAN_DURATION` | ~1 year | Maximum loan duration in blocks |
| `MIN_LOAN_AMOUNT` | 1 STX | Minimum borrowable amount |

## 🧪 Testing

### Run Unit Tests

```bash
clarinet test
```

### Integration Testing

```bash
clarinet console
```

Example test scenarios:

```clarity
;; Test loan creation
(contract-call? .bitstack-lending deposit-btc-collateral u100000000)
(contract-call? .bitstack-lending create-loan u1000000000 u75000000)

;; Test liquidation scenario
(contract-call? .bitstack-lending update-btc-price u25000000) ;; Simulate price drop
(contract-call? .bitstack-lending liquidate-loan u1)
```

## 🚨 Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `ERR_NOT_AUTHORIZED` | Caller not authorized for this action |
| u101 | `ERR_INSUFFICIENT_COLLATERAL` | Not enough collateral for loan |
| u102 | `ERR_LOAN_NOT_FOUND` | Loan ID does not exist |
| u103 | `ERR_LOAN_ALREADY_EXISTS` | Loan ID already in use |
| u104 | `ERR_INSUFFICIENT_BALANCE` | Insufficient STX balance |
| u105 | `ERR_LIQUIDATION_NOT_ALLOWED` | Loan not eligible for liquidation |
| u106 | `ERR_INVALID_AMOUNT` | Invalid loan or collateral amount |
| u107 | `ERR_LOAN_EXPIRED` | Loan has exceeded duration |
| u108 | `ERR_REPAYMENT_FAILED` | Loan repayment failed |

## 🛠️ API Reference

### Public Functions

#### `deposit-btc-collateral(btc-amount: uint)`
Deposit Bitcoin as collateral for future loans.

**Parameters:**
- `btc-amount`: Amount in satoshis

**Returns:** `(response uint uint)`

#### `create-loan(stx-amount: uint, btc-collateral-amount: uint)`
Create a new STX loan against Bitcoin collateral.

**Parameters:**
- `stx-amount`: STX amount to borrow (micro-STX)
- `btc-collateral-amount`: BTC collateral to lock (satoshis)

**Returns:** `(response uint uint)` - Loan ID on success

#### `repay-loan(loan-id: uint)`
Repay an active loan with accumulated interest.

**Parameters:**
- `loan-id`: ID of loan to repay

**Returns:** `(response uint uint)` - Total amount paid

#### `liquidate-loan(loan-id: uint)`
Liquidate an undercollateralized or expired loan.

**Parameters:**
- `loan-id`: ID of loan to liquidate

**Returns:** `(response uint uint)` - Collateral amount liquidated

### Read-Only Functions

#### `get-loan(loan-id: uint)`
Retrieve loan details by ID.

#### `get-loan-status(loan-id: uint)`
Get comprehensive loan status including interest owed.

#### `get-user-loans(user: principal)`
Get all loan IDs for a specific user.

#### `calculate-required-collateral(stx-amount: uint)`
Calculate minimum BTC collateral needed for STX loan amount.

## 🌐 Integration Examples

### Frontend Integration (JavaScript)

```javascript
import { StacksMainnet } from '@stacks/network';
import { AnchorMode, PostConditionMode, makeContractCall } from '@stacks/transactions';

// Create loan transaction
const createLoan = async (stxAmount, btcCollateral, senderKey) => {
  const network = new StacksMainnet();
  
  const txOptions = {
    contractAddress: 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX975CN7QCR',
    contractName: 'bitstack-lending',
    functionName: 'create-loan',
    functionArgs: [
      uintCV(stxAmount),
      uintCV(btcCollateral)
    ],
    senderKey,
    network,
    anchorMode: AnchorMode.Any,
    postConditionMode: PostConditionMode.Allow,
  };

  return await makeContractCall(txOptions);
};
```

### Price Oracle Integration

```javascript
// Update BTC/STX price (authorized callers only)
const updatePrice = async (newPrice, senderKey) => {
  const txOptions = {
    contractAddress: 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX975CN7QCR',
    contractName: 'bitstack-lending',
    functionName: 'update-btc-price',
    functionArgs: [uintCV(newPrice)],
    senderKey,
    network: new StacksMainnet(),
    anchorMode: AnchorMode.Any,
  };

  return await makeContractCall(txOptions);
};
```

## 🚀 Roadmap

### Phase 1: Core Protocol (Current)
- ✅ Basic lending and borrowing functionality
- ✅ Bitcoin collateral management
- ✅ Interest calculation and repayment
- ✅ Liquidation mechanism

### Phase 2: Enhanced Features
- [ ] Dynamic interest rates based on utilization
- [ ] Governance token integration
- [ ] Multi-collateral support (other Bitcoin L2 assets)
- [ ] Flash loan functionality

### Phase 3: Advanced Integration
- [ ] Cross-chain Bitcoin bridges
- [ ] Lightning Network integration
- [ ] Automated market makers for liquidations
- [ ] Insurance fund for protocol protection

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Clarity coding standards
- Add comprehensive tests for new features
- Update documentation for API changes
- Ensure gas optimization for all functions

## 🏆 Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Clarity language development team
- Bitcoin and Stacks community contributors

---

**Built with ❤️ on Stacks • Secured by Bitcoin**