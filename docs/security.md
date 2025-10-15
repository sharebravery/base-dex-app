# Security notes

Scope of this document is the DEX release on branch `phase-4-user-data-release`.
Deferred items are called out; nothing here is a claim of production
readiness.

## Wallet key lifecycle and adapter boundary

- The only surface the app talks to is `WalletService` (interface in
  `apps/mobile/lib/features/auth/wallet_service.dart`). It exposes
  `restoreSession()`, `login()`, `signMessage()`, `signTransaction()`,
  `logout()` — no `getPrivateKey`-style method on the interface.
- The production adapter is `Web3AuthWalletService`; test/dev code MUST NOT
  extend or import it directly, only the interface. Boundary is enforced by
  `test/features/auth/wallet_service_boundary_test.dart`.
- Private key material never crosses the interface. Signing happens inside the
  adapter; only `EvmTransactionRequest` (unsigned) goes in, only signed hex
  bytes come out.

## Device-auth limitations

- `BiometricGate` wraps `local_auth`. Confirmation is enforced before every
  `TradeExecutor.execute(...)` call.
- `LocalAuthBiometricGate` uses `biometricOnly: false` and
  `persistAcrossBackgrounding: true`. This means device passcode is an
  accepted fallback: on an unlocked device without a strong biometric, a
  passcode is sufficient to confirm a swap. This is intentional for demo but
  a hardened build should flip `biometricOnly: true`.
- The Flutter `local_auth` plugin platform channel is not currently exercised
  in automated tests; a device-attached run is required to prove the prompt
  actually appears.

## SIWE domain / URI / chainId / nonce checks

- `/v1/auth/challenge` issues a fresh nonce with a bounded expiry (see
  `apps/api/src/auth/service.ts`; `consumeNonce` refuses replay).
- `/v1/auth/verify` recomputes the SIWE message from the request body and
  verifies the signature against the wallet address. Domain, URI, chainId
  (8453 = Base), and nonce fields are validated before session issuance.
- Replay is prevented at the nonce store: successful consumption deletes
  the nonce entry. See `apps/api/test/auth.test.ts`.

## JWT storage and expiry

- The Worker mints a short-lived app-session JWT signed with a Worker-side
  secret; the mobile client stores it in `flutter_secure_storage` (keychain /
  keystore backing), not `SharedPreferences`.
- `requireAppSession` middleware in `apps/api/src/auth/middleware.ts` checks
  signature + expiry on every protected route (`/v1/profile`, `/v1/settings`,
  `/v1/watchlist`, `/v1/trades*`).

## Router allowlist

- `TransactionService` refuses to sign an approve whose spender does not equal
  the injected `allowedSpender`, and refuses to sign a swap whose
  `quote.transactionTo` does not equal the injected `allowedSettler`.
- Both allowlisted addresses come from build-time constants pointing at the
  KyberSwap Base router (`0x6131B5fae19EA4f9D964eAc0408E4408b66337b5`) and are
  held constant across a session; they are NOT taken from the quote payload.
- The demo path never reaches these guards — the route-preview quote carries
  `transactionData: null` and `TradeExecutor` short-circuits before signing.
  The checks stay in place to prevent regressions if the `/route/build`
  broadcast path is ever wired.

## Exact approval policy

- Approvals use ERC-20 `approve(spender, exactAmount)` with `exactAmount ==
  quote.sellAmount`, encoded by `encodeApprove()` (selector `0x095ea7b3`).
- No infinite approvals. `TradeExecutor` reads current allowance, and skips
  the approval leg entirely when `current >= quote.sellAmount`.

## Receipt / log verification

- After a swap is broadcast (not exercised in demo mode), the mobile client
  posts `{ txHash }` to `/v1/trades/verify`. The Worker fetches the receipt +
  transaction via `eth_getTransactionReceipt` / `eth_getTransactionByHash`
  and asserts:
  - `chainId == 8453`
  - `receipt.status == 1`
  - `receipt.from == authenticatedWallet`
  - `receipt.to == env.ALLOWED_SETTLER`
  - a `Transfer(address,address,uint256)` USDC log involving the wallet
    address is present, decoded to `buy_eth` or `sell_eth`.
- All five assertions are unit-tested in `apps/api/test/trades.test.ts`.

## Logging redaction

- The Worker MUST NOT log wallet private keys, session JWTs, or SIWE
  signatures. A CI grep gate refuses any commit that adds a private-key
  handle (getter method whose name ends in `PrivateKeyForSigning`) or a raw
  PEM block header.
- The Flutter client logs are limited to public tx hashes and addresses.

## CORS allowlist

- The Worker uses a dynamic origin allowlist (see `apps/api/src/index.ts`).
  Non-browser callers (Flutter native / curl / server-to-server, i.e. no
  `Origin` header) pass through. Browser clients must match:
  - `CORS_ORIGINS` env (comma-separated; supports single-level `*` wildcard)
  - `http://localhost:*` / `http://127.0.0.1:*` in dev (`APP_ENV != production`)
- No wildcard `*` fallback in production.

## Restricted database role

- The Drizzle client connects through Hyperdrive with a restricted DB role
  that only holds `SELECT/INSERT/UPDATE/DELETE` on the app tables listed in
  `docs/architecture.md`. It does NOT hold `DROP`, `TRUNCATE`, `ALTER`, or
  role-management privileges.
- Nonces auto-expire; `app_trades` inserts use `onConflictDoNothing` keyed on
  `(chainId, txHash)` — duplicate submissions are idempotent.

## Staging mainnet verification limits

- A controlled staging Base mainnet swap is DEFERRED to a manual operator
  step and is NOT part of the automated Task 13 harness. See the checklist
  below.
- Recommended staging wallet: a dedicated, low-value wallet not used for
  anything else. Never point the mobile debug build at a wallet holding
  significant funds.

## Manual verification checklist (operator-run)

Before promoting a build past demo mode:

1. Confirm `env.ALLOWED_SETTLER` matches the current KyberSwap Base router
   (`0x6131B5fae19EA4f9D964eAc0408E4408b66337b5`) — cross-check on BaseScan.
2. Confirm the shipped USDC contract equals the canonical Base USDC address
   (`0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913`).
3. If enabling real swaps (out of scope for this branch): wire KyberSwap
   `/route/build` and perform one low-value swap with a dedicated staging
   wallet. Manually compare `chainId`, `sellAmount`, `minBuyAmount`,
   `allowanceTarget`, `transactionTo`, and `gas` against the Quote.
4. Verify the resulting `app_trades` row on Postgres:
   `(chainId, txHash)` should be unique and `direction` should match the
   receipt logs.
5. Attempt a second submission of the same `txHash`; the API should return
   the same success payload without duplicating the row.

## Explicit audit statement

Audit completion is not claimed. This repository has NOT been through an
independent third-party security audit. The controls above are internal
best-effort guardrails.
