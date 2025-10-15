# Two-minute demo script

Target duration: 2:00. Each cue is a milestone, not a script.

```
0:00–0:15  Market catalog — live Binance prices, English/Chinese switch
0:15–0:30  ETH detail, real 1D/7D/30D chart (Binance klines), only ETH is Tradable
0:30–0:45  Wallet demo session, Portfolio shows real on-chain Base balances
0:45–1:05  Trade page — enter a USDC amount, live KyberSwap Price + Review
1:05–1:30  Confirmation Sheet — real minBuyAmount, route (Curve/Aerodrome/…),
           router destination. Demo badge makes clear nothing broadcasts.
1:30–1:45  Portfolio — paste any Base address, see real ETH+USDC balances
1:45–2:00  Architecture slide: KyberSwap + Binance + Base RPC (all free, no key),
           tests + security boundaries
```

## Cue notes

- **0:00–0:15** Land on the Market catalog. Numbers are live Binance
  `/api/v3/ticker/24hr` output. Toggle system language to zh in Settings to
  show the ARB copy switch.
- **0:15–0:30** Tap ETH. Chart is a real `LineChart` over Binance klines
  (`1d` = 30 daily bars, `7d` / `30d` = hourly). Toggle the interval to
  emphasise the re-render is instant (Worker `Cache-Control` + Riverpod
  family caches per `(assetId, interval)`).
- **0:30–0:45** Portfolio tab — the demo session address is the Binance 8
  hot wallet on Base. Balances come straight from `mainnet.base.org` via
  web3dart. Numbers change if the wallet moves.
- **0:45–1:05** Trade page. AppBar has a persistent "Demo" chip; body has a
  banner reading "Demo · quotes are real, nothing is broadcast on-chain".
  Type a USDC amount — after a 350 ms debounce the Worker hits KyberSwap
  `/base/api/v1/routes` and the indicative price updates.
- **1:05–1:30** Tap Review. Confirmation Sheet lists:
  - Pay / Receive / Minimum Received (computed from slippage on the fly)
  - Route (real path, e.g. `curve-stable-ng · aerodrome-cl · solidly-v3`)
  - Spender / Destination = KyberSwap router `0x6131…37b5`
  - A yellow-ish info banner + a Confirm button labelled "Show demo
    confirmation". Tapping it snacks `Demo · quote acknowledged, nothing
    broadcast` and never enters `TradeExecutor.execute`.
- **1:30–1:45** Back to Portfolio. The address picker at the top accepts
  any Base address — paste a whale like `vitalik.eth` (resolved off-app)
  or a memelord wallet, tap Load, real ETH + USDC balances render.
- **1:45–2:00** Cut to a slide showing:
  - `apps/api/src/swap/client.ts` → KyberSwap (free, no key)
  - `apps/api/src/market/client.ts` → Binance klines + tickers (free, no key)
  - `apps/mobile/lib/features/portfolio/portfolio_repository.dart` → Base
    public RPC
  - Test summary: `pnpm test` (31 pass) + `flutter test` (43 pass)
  - Security notes from `docs/security.md` — CORS allowlist, exact-amount
    approvals guard, KyberSwap router allowlist, audit disclaimer