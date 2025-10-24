# DEX Architecture

Snapshot of what actually ships on branch `phase-4-user-data-release`. Deferred
items are called out explicitly so nothing gets over-claimed.

## Repository map

```
apps/
  mobile/          Flutter 3.44 / Dart 3.12 client
    lib/
      app/         MaterialApp + router shell
      core/        web3 primitives, security gate, http/network helpers
      features/    feature-scoped Riverpod slices (see below)
      l10n/        ARB files + generated AppLocalizations (en, zh)
      theme/       AppTheme + AppColors
    test/          mirrors lib/ layout + goldens/ + integration/
  api/             Cloudflare Worker (Hono + Drizzle)
    src/
      auth/        SIWE challenge / verify + session middleware
      market/      /v1/markets, /v1/candles
      profile/     /v1/profile, /v1/settings, /v1/watchlist
      swap/        /v1/swap/price, /v1/swap/quote (KyberSwap route-preview)
      trades/      /v1/trades, /v1/trades/verify + receipt verifier
      db/          Drizzle schema + Hyperdrive-backed client factory
    test/          vitest, one file per feature slice
docs/              this directory
```

## Flutter feature convention

Every user-facing feature lives under `apps/mobile/lib/features/<feature>/`
with a shallow structure:

- `<feature>_models.dart` — plain Dart / freezed value objects
- `<feature>_repository.dart` — I/O contract + concrete implementation
- `<feature>_controller.dart` — orchestration; either a `ChangeNotifier` or a
  plain class exposed via Riverpod
- `<feature>_screen.dart` / `widgets/` — presentation
- `<feature>_providers.dart` (optional) — Riverpod providers for that slice

Feature slices in the repo today:

- `auth/` — wallet session + Web3Auth adapter (adapter deferred; `WalletService`
  interface is stable).
- `market/` — market catalog, pair detail, static fixture loader.
- `trade/` — TradeController + SwapRepository + TradeExecutor + confirmation
  sheet + TransactionService + TransactionTracker + PendingTransactionStore.
- `portfolio/` — snapshot models, RPC-backed repository, deposit sheet,
  withdraw controller/screen, activity controller.
- `settings/` — theme + language preference persistence.

## Riverpod dependency graph (partial, wired providers only)

```
walletServiceProvider           (throws until bootstrap wiring)
appSessionRepositoryProvider    -> AppSessionRepository(prefs)
authControllerProvider          -> AuthController(walletService, session)

portfolioRepositoryProvider     (throws until bootstrap wiring)
portfolioControllerProvider     -> PortfolioController(repo)
ethPriceUsdProvider             (throws; overridden by Market)
portfolioSnapshotProvider(addr) -> Future<PortfolioSnapshot>

settingsRepositoryProvider      -> SettingsRepository(prefs)
settingsControllerProvider      -> SettingsController(repo)
```

TradeController, TradeExecutor, TransactionService, TransactionTracker,
PendingTransactionStore, and SwapRepository are constructor-injected in tests
today; their Riverpod providers are DEFERRED until app bootstrap wiring in
Phase 5.

## Worker route contracts

| Method | Path                 | Auth        | Purpose                                     |
| ------ | -------------------- | ----------- | ------------------------------------------- |
| GET    | `/health`            | none        | Liveness                                    |
| POST   | `/v1/auth/challenge` | none        | Issue SIWE nonce                            |
| POST   | `/v1/auth/verify`    | none        | Verify SIWE signature, mint app session JWT |
| GET    | `/v1/profile`        | app session | Return profile row for authenticated wallet |
| PUT    | `/v1/settings`       | app session | Persist theme / locale                      |
| GET    | `/v1/watchlist`      | app session | Return watchlist symbols                    |
| PUT    | `/v1/watchlist`      | app session | Replace watchlist symbols                   |
| GET    | `/v1/markets`        | none        | 24h ticker catalog via Binance              |
| GET    | `/v1/candles`        | none        | OHLC series via Binance klines              |
| POST   | `/v1/swap/price`     | none        | KyberSwap `/routes` proxy (route preview)   |
| POST   | `/v1/swap/quote`     | none        | KyberSwap `/routes` proxy (route preview)   |
| POST   | `/v1/trades/verify`  | app session | Recheck on-chain receipt + insert app trade |
| GET    | `/v1/trades`         | app session | List app trades for the profile             |

## Data providers

All read paths use free, keyless public APIs:

- **Prices & 24h stats**: Binance REST `/api/v3/ticker/24hr` (weight 2, no key)
- **Candles**: Binance REST `/api/v3/klines` — `1d` returns 30 daily bars,
  `7d` returns 168 hourly bars, `30d` returns 720 hourly bars
- **Swap route + quote**: KyberSwap aggregator `/base/api/v1/routes` — no API
  key; only a `x-client-id` header (`env.KYBERSWAP_CLIENT_ID`, defaults
  to `dex-demo`) so we get non-throttled rate limits
- **Portfolio balances**: `https://mainnet.base.org` public RPC via web3dart

The mobile client never calls these providers directly — everything goes
through the Worker so we can layer caching (`Cache-Control` on Binance
proxies) and CORS on top.

## Settlement boundary

The swap flow currently uses KyberSwap's `/routes` route-preview. That endpoint
returns `amountOut`, `gas`, `l1FeeUsd`, `route[]`, and the router address -
everything the quote UI needs. Producing a signable transaction additionally
requires `/route/build` for encoded calldata; the client treats a `null`
`transactionData` on the quote as the signal that only a preview is available
and:

1. Surfaces the route / quote details on the Trade screen and Confirmation Sheet.
2. Completes the confirm flow client-side without dispatching
   `TradeExecutor.execute`.
3. Displays the router address as the destination row, formatted as
   `0x6131…37b5` (short address), so it can be copied onto BaseScan.

On-chain signing / broadcast re-enters through the `TradeExecutor` path once a
build-flag flips (`APP_ENV == 'production'`) AND the Worker adds a
`/route/build` step.

## SIWE sequence

```
Mobile                                     Worker (Hono)                DB
  |  POST /v1/auth/challenge {address}       |                            |
  | --------------------------------------> |                            |
  |                                          | insert siwe_nonces         |
  |                                          | ------------------------> |
  |  { nonce, expiresAt }                    |                            |
  | <-------------------------------------- |                            |
  |  signMessage(nonce+domain+chainId+uri)   |                            |
  |  POST /v1/auth/verify {signature,...}    |                            |
  | --------------------------------------> |                            |
  |                                          | verifyMessage()            |
  |                                          | consumeNonce()             |
  |                                          | upsert profiles            |
  |                                          | mint session JWT           |
  |  { accessToken, walletAddress }          |                            |
  | <-------------------------------------- |                            |
```

## Price -> Quote sequence

```
User types amount -> TradeController.updateAmount()
                     debounce 350 ms
                     -> SwapRepository.getPrice()
                     -> state.price populated, error state cleared

User taps Review  -> TradeController.review()
                     -> SwapRepository.getQuote()
                     -> state.quote populated (fresh window = validFor)
                     ConfirmationSheet enables Confirm iff quote.isFreshAt(now).
```

## Approve -> Swap sequence

```
TradeExecutor.execute(quote):
  quote.isFreshAt(now) or throw
  BiometricGate.authenticate() or throw TradeExecutionCancelled
  if quote.allowanceTarget != null:
      current = ChainGateway.allowance(owner, sellToken, spender)
      if current < quote.sellAmount:
          approvalHash = TransactionService.approveExact(exact = quote.sellAmount)
          ChainGateway.waitForSuccess(approvalHash)
  swapHash = TransactionService.swap(quote)
  return { approvalTxHash, swapTxHash }
```

TransactionService rejects any approval whose `spender != allowedSpender`, and
any swap whose `quote.transactionTo != allowedSettler`, before signing.

## Pending recovery sequence

```
App start
  PendingTransactionStore.loadAll()   (SharedPreferences key: pending_transactions_v1)
  TransactionTracker.resumeForWallet(walletAddress)
    for each pending item -> track():
      poll ReceiptSource at [2s, 3s, 5s, 8s, 13s, 20s]
      on confirmed|reverted -> store.remove(txHash) -> resolve
      on max intervals reached -> leave in store, resolve as pending
```

TransactionTracker is idempotent — resuming twice with the same store yields
the same store state after each poll completes.

## Database table responsibilities (Drizzle, Postgres via Hyperdrive)

- `profiles` — one row per authenticated wallet; owns downstream FKs.
- `siwe_nonces` — short-lived nonces for the SIWE challenge/verify cycle.
- `user_settings` — theme + locale + slippage preference per profile.
- `watchlists` — profile-owned market symbols; PUT replaces the set.
- `app_trades` — verified trades keyed by `(chainId, txHash)` with
  `onConflictDoNothing` on insert; stores decoded direction/amounts and the
  RPC receipt block for later reconciliation.

## Deferred / not-yet-wired

- Web3Auth adapter (`Web3AuthWalletService`) is a thin shim; real network calls
  are not exercised end-to-end.
- Live Supabase/Postgres connection is not exercised in tests; Drizzle client
  factory expects Hyperdrive bindings.
- KyberSwap `/route/build` (which returns encoded calldata + `sender`
  binding). Without it the client shows the route/quote but cannot sign a
  transaction — see "Settlement boundary" above.
- Native biometric plugin wiring (`local_auth`) — `LocalAuthBiometricGate` is
  implemented; the plugin platform channel is not exercised in tests.
- End-to-end integration tests via the `integration_test` package (deferred to
  a device-attached job; the release harness runs a widget-test proxy at
  `apps/mobile/test/integration/trade_flow_test.dart`).
