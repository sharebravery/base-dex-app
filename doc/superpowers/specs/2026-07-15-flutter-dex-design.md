# Flutter DEX Product Design

**Date:** 2026-07-15  
**Status:** Approved product direction; awaiting written-spec review  
**Platform:** Flutter for iOS and Android  
**Working description:** Apple-inspired mobile DEX with an embedded recoverable wallet

## 1. Product Summary

Build a visually refined Flutter DEX that feels as easy to use as a modern centralized exchange while keeping settlement on-chain. Users sign in with email, Apple, or Google; an embedded wallet is created and recoverable through a third-party wallet infrastructure provider. Trading happens inside the app without switching to an external wallet.

The product is not a full wallet and not a centralized exchange. It is a focused mobile trading product with three core areas:

1. Market discovery
2. Spot-style buy and sell experience backed by DEX swaps
3. Portfolio and transaction tracking

## 2. Product Positioning

> A simple, polished mobile DEX with exchange-like usability and on-chain settlement.

### Primary value

- No external wallet jump during signing
- Familiar buy and sell language instead of exposing unnecessary Web3 terminology
- Clear, elegant mobile interface inspired by Apple-like restraint and the product density of Bitget Wallet
- Real chain interactions rather than a simulated trading interface

### Target user

The first version targets crypto-aware users who understand basic ideas such as tokens and buying or selling, but do not want to manage wallet infrastructure or complex on-chain settings.

It is also designed as a portfolio project that demonstrates:

- Advanced Flutter UI engineering
- Real-time market data
- Interactive charts
- Embedded wallet integration
- DEX quoting and transaction execution
- On-chain transaction state tracking

## 3. Product Principles

### 3.1 Exchange-like surface, DEX underneath

Users interact with familiar concepts such as Buy, Sell, Deposit, Withdraw, Holdings, and History. Internally, buying and selling are token swaps executed through a DEX route.

### 3.2 Hide complexity, never hide consequences

The interface may hide RPC, nonce, gas limit, approval calldata, and routing details by default. It must still show:

- What the user pays
- What the user receives
- Estimated network fee
- Minimum received amount
- Price impact
- Approval requirement
- Irreversibility of the transaction

### 3.3 One polished flow before many features

The first version optimizes this path:

```text
Sign in
→ Open a trading pair
→ Review chart and market information
→ Enter buy or sell amount
→ Receive DEX quote
→ Confirm with biometrics
→ Track on-chain completion
→ See updated holdings
```

### 3.4 Motion supports comprehension

Animations should connect state changes and explain progress. They should not be decorative spectacle.

Primary motion moments:

- Market card expanding into pair details
- Buy/sell sheet opening from the selected asset
- Quote refreshing without layout jumps
- Confirmation card becoming a transaction timeline
- Portfolio balance updating after confirmation

## 4. Scope

## 4.1 Version 1 features

### Authentication and embedded account

- Email login
- Apple login on iOS
- Google login on Android and supported platforms
- Automatic embedded wallet creation
- Recovery of the same wallet on another device through the wallet provider
- Local biometric confirmation before requesting a signature
- Wallet address display and copy action

### Market

- Watchlist
- Popular pairs
- Top gainers and losers
- Token and pair search
- Pair details
- Current price
- 24-hour change
- 24-hour volume
- Price chart
- Candlestick chart with a small set of intervals

### Trading

- Buy and Sell modes
- Token pair selection
- Amount input in token or fiat equivalent
- Available balance
- DEX quote retrieval
- Estimated output
- Minimum received
- Network fee estimate
- Price impact
- Token approval when required
- Biometric confirmation
- Signature through the embedded wallet
- Transaction broadcast
- Transaction timeline
- Success and failure states

### Portfolio

- Total portfolio value
- Daily value change
- Token holdings
- Token allocation
- Average acquisition price based on trades executed in the app
- Unrealized profit and loss based on app-recorded cost basis
- Deposit address and QR code
- Withdraw as an on-chain transfer
- Transaction history

### Settings

- Profile
- Currency preference
- Language preference
- Appearance mode
- Security and biometric settings
- Wallet address details
- Legal and risk disclosures
- Sign out

## 4.2 Explicitly excluded from Version 1

- Full seed phrase wallet product
- Manual private-key import
- Multiple wallet management
- WalletConnect connection to external dApps
- NFT gallery
- dApp browser
- Cross-chain swaps
- Bridge aggregation
- Limit orders
- Order book matching
- Perpetual futures
- Leverage
- Copy trading
- Staking or yield products
- Custom RPC configuration
- Token launchpad
- AI trading agent
- Autonomous trading
- Platform token or points economy

## 5. Navigation and Information Architecture

Use three primary bottom-navigation destinations:

```text
Market | Trade | Portfolio
```

Profile and settings are opened from the avatar in the upper-right corner.

### Market

- Search
- Watchlist
- Popular pairs
- Gainers and losers
- Market cards
- Pair detail page

### Trade

- Selected pair header
- Compact chart
- Buy/Sell segmented control
- Amount entry
- Quote summary
- Expandable details
- Confirm action

### Portfolio

- Total value
- Daily change
- Holdings
- Allocation
- Deposit and Withdraw
- Transaction history

## 6. Core Screens

## 6.1 Welcome and sign-in

The sign-in screen should feel like a financial product rather than a wallet setup wizard.

Primary actions:

- Continue with Apple
- Continue with Google
- Continue with email

Do not introduce seed phrases, private keys, RPC networks, or wallet terminology during onboarding.

After sign-in, explain in one sentence:

> Your trading account is created on-chain and recoverable through your login.

## 6.2 Market home

Visual hierarchy:

1. Search and profile
2. Watchlist summary
3. Popular market cards
4. Gainers and losers
5. Full pair list

Cards should show only the information needed for scanning:

- Pair symbol
- Current price
- Percentage change
- Small sparkline

## 6.3 Pair detail

The pair detail page connects market research to trading.

Content:

- Pair and current price
- 24-hour statistics
- Interactive chart
- Time interval selector
- User holding summary
- Persistent Buy and Sell actions

Advanced chart indicators are excluded from Version 1. The chart should prioritize touch interaction, smooth zooming, crosshair values, and visual clarity.

## 6.4 Trade screen

Buy and Sell are user-facing concepts. Internally:

```text
Buy ETH with USDC = USDC → ETH swap
Sell ETH for USDC = ETH → USDC swap
```

Default content:

- Current pair
- Market price
- Buy/Sell toggle
- Amount field
- Fiat equivalent
- Available balance
- Primary action

Expandable details:

- Route
- Network fee
- Price impact
- Minimum received
- Approval status
- Slippage protection

## 6.5 Confirmation sheet

Before signing, show a human-readable balance transition:

```text
You pay:       100.00 USDC
You receive:   approximately 0.031 ETH
Network fee:   approximately $0.04
Minimum:       0.0308 ETH
```

The main action should state the actual operation, such as:

- Confirm Buy
- Confirm Sell
- Approve USDC

After biometric confirmation, the sheet transforms into the transaction timeline rather than closing and showing an unrelated loading screen.

## 6.6 Transaction timeline

Use the same component for approval, swap, deposit detection, and withdrawal:

```text
Preparing
→ Awaiting confirmation
→ Submitted on-chain
→ Confirmed
→ Portfolio updated
```

Failure states should explain what happened and what the user can do next.

Examples:

- Not enough network token to pay the fee
- Quote expired because the price changed
- Approval was rejected
- Transaction reverted on-chain
- Network request timed out but the transaction may still be pending

## 7. Visual Design Direction

### 7.1 Character

- Calm
- Premium
- Financial
- Modern
- Dense enough to feel capable
- Spacious enough to remain readable

### 7.2 Apple-inspired qualities

- Strong typography hierarchy
- Large, confident portfolio values
- Soft surfaces and restrained shadows
- Consistent corner radius
- Clear separation through spacing before borders
- Native-feeling motion
- High-quality light and dark modes
- Minimal use of gradients
- No neon cyberpunk theme
- No excessive glassmorphism

### 7.3 Color strategy

Use one primary accent color for selected states and important actions. Profit and loss colors are semantic and should not dominate the interface.

### 7.4 Motion strategy

- Standard interaction: 150–220 ms
- Sheet and page transitions: 220–320 ms
- Balance and quote changes: subtle animated number transitions
- Transaction progress: continuous state transition without fake progress percentages

## 8. System Architecture

```text
Flutter App
├── Presentation Layer
│   ├── Market
│   ├── Trading
│   ├── Portfolio
│   └── Account
├── Application Layer
│   ├── Authentication orchestration
│   ├── Quote orchestration
│   ├── Trade execution
│   ├── Portfolio calculation
│   └── Transaction tracking
├── Domain Layer
│   ├── MarketPair
│   ├── Token
│   ├── Quote
│   ├── Trade
│   ├── Holding
│   └── Transaction
└── Infrastructure Layer
    ├── Embedded wallet provider
    ├── Market data provider
    ├── DEX quote and route provider
    ├── EVM RPC provider
    ├── Local secure storage
    └── Backend API
```

### Backend responsibilities

A lightweight backend may handle:

- Normalized market data
- Historical candles
- Watchlist synchronization
- Token metadata
- Push-notification registration
- App trade history metadata
- Provider-key protection
- Rate limiting

The backend must not store raw private keys or independently sign user transactions.

## 9. Chain and Trading Boundaries

Version 1 supports one EVM network: **Base**.

Reasons for this product choice:

- Keeps balances, fees, RPC state, and token lists manageable
- Avoids cross-chain routing and bridge UX
- Allows the team to polish one complete transaction flow

Version 1 supports a curated set of liquid pairs rather than arbitrary token contracts. Initial product examples:

- ETH / USDC
- cbBTC / USDC
- A small number of additional high-liquidity pairs

Quotes should come from one DEX aggregator or routing provider behind an internal abstraction so the provider can be replaced later.

## 10. Embedded Wallet Model

The embedded wallet provider is responsible for account creation, recovery, and signing infrastructure.

The app is responsible for:

- User authentication flow
- Clear signing consent
- Biometric gate on the device
- Human-readable transaction details
- Displaying wallet address and asset ownership
- Handling provider failure safely

Required product behavior:

- Signing must never happen silently
- The user must approve the amount and destination context
- Recovery must restore the same on-chain address
- Signing errors must not expose low-level provider messages directly
- The user must be informed that the account is blockchain-based and transactions are irreversible

## 11. Data Flow

### 11.1 Login

```text
User authenticates
→ Embedded wallet provider resolves or creates account
→ App receives account address and authorized signing session
→ Backend associates app profile with public address
→ Portfolio loads
```

### 11.2 Quote

```text
User enters amount
→ App validates balance and pair
→ Quote service requests route
→ App receives output, fee, impact, minimum received, and expiry
→ UI renders quote
→ Quote refreshes when expired or materially changed
```

### 11.3 Trade execution

```text
User reviews confirmation sheet
→ Biometric gate succeeds
→ Approval transaction executes if required
→ Swap transaction is prepared
→ Embedded wallet requests explicit signing consent
→ Transaction broadcasts
→ Tracker monitors receipt
→ Portfolio and trade history refresh
```

## 12. Error Handling

Errors are grouped into user-actionable categories:

### Authentication

- Login cancelled
- Session expired
- Recovery unavailable

### Market data

- Price temporarily unavailable
- Chart history unavailable
- Stale data warning

### Quote

- No route available
- Insufficient liquidity
- Price impact too high
- Quote expired

### Wallet and transaction

- Insufficient token balance
- Insufficient network fee balance
- User rejected confirmation
- Approval failed
- Transaction reverted
- Transaction pending longer than expected

Every error should provide:

1. A plain-language title
2. A short explanation
3. A safe next action
4. Technical details behind an expandable section

## 13. Security and Trust Requirements

- Never store raw private keys in the app backend
- Never log sensitive signing payloads or authentication secrets
- Require explicit consent for every approval and swap
- Show approval amount and spender context
- Use encrypted local storage for sessions and non-exportable device secrets where supported
- Re-authenticate after an inactivity timeout
- Lock high-risk actions behind biometrics or device authentication
- Validate chain ID and contract addresses before signing
- Maintain a curated token and contract allowlist for Version 1
- Display pending transactions after app restart
- Treat remote market and token metadata as untrusted input

## 14. Analytics and Success Criteria

The first version succeeds when a new user can complete the primary flow without understanding wallet infrastructure.

Key measurements:

- Sign-in completion rate
- Wallet creation or recovery success rate
- Pair-detail-to-trade conversion
- Quote success rate
- Confirmation abandonment rate
- Approval success rate
- Swap success rate
- Median time from confirmation to portfolio update
- Number of users adding a watchlist pair
- Crash-free sessions

Portfolio-project success also requires:

- A polished recorded demo under two minutes
- A complete real testnet or controlled mainnet transaction
- Clear architecture documentation
- Reusable Flutter chart and transaction-timeline components
- Automated tests around quote state and transaction state transitions

## 15. Testing Strategy

### Unit tests

- Quote expiry and refresh rules
- Buy and Sell token-direction mapping
- Fee and minimum-received formatting
- Portfolio value calculations
- Cost-basis calculations for in-app trades
- Transaction state machine
- Error translation

### Widget tests

- Market list loading and empty states
- Buy/Sell form validation
- Confirmation sheet contents
- Approval step visibility
- Transaction timeline states
- Light and dark mode rendering

### Integration tests

- Authentication to wallet recovery
- Quote retrieval
- Approval and swap flow on testnet or forked environment
- Transaction receipt tracking
- App restart while a transaction is pending

### Visual regression tests

- Market home
- Pair detail
- Trade screen
- Confirmation sheet
- Portfolio
- Light and dark themes

## 16. Delivery Sequence

The implementation should proceed in this order:

1. Design system and navigation shell
2. Static market and pair-detail experience
3. Real market data and charts
4. Embedded-wallet login and account recovery
5. Portfolio balance loading
6. DEX quoting
7. Approval and swap execution
8. Transaction timeline and recovery after restart
9. Deposit, withdrawal, and history
10. Polish, testing, and demo preparation

## 17. Future Iterations

After Version 1 is stable, suitable additions are:

- AI explanation of quote, approval, and transaction failures
- Gas sponsorship through smart-account infrastructure
- Passkey-first signing
- Limit orders through an external protocol
- Multi-network portfolio view
- Cross-chain routing
- Advanced chart indicators
- Price alerts and push notifications

AI remains advisory. It should not autonomously sign transactions or manage funds in the initial product roadmap.

## 18. Final Scope Statement

Version 1 is a three-tab Flutter DEX with an embedded recoverable wallet, one EVM network, curated spot pairs, real market data, interactive charts, DEX-based Buy and Sell, biometric confirmation, and a polished transaction timeline.

The project intentionally prioritizes visual quality, interaction quality, and one complete on-chain trade flow over broad wallet functionality or exchange infrastructure.
