# Two-minute demo script

Target duration: 2:00. Each cue is a milestone, not a script.

```
0:00–0:15  Market catalog, responsive layout, English/Chinese switch
0:15–0:30  ETH detail, chart, only ETH/USDC marked Tradable
0:30–0:45  Web3Auth wallet restoration and address
0:45–1:05  Price while editing, Review, firm Quote details
1:05–1:30  Device auth, exact USDC Approve, Swap timeline
1:30–1:45  Tx Hash, Base explorer, Portfolio refresh
1:45–2:00  Architecture, automated tests, security boundaries
```

## Cue notes

- **0:00–0:15** Land on the Market catalog. Toggle system language to zh in
  Settings to show the ARB-driven copy switch; both locales are covered by
  the golden suite at 390×844.
- **0:15–0:30** Tap ETH. Highlight the "Tradable" badge — every other asset
  is market-data-only. The pair-detail chart uses cached OHLC.
- **0:30–0:45** Tap Sign in with email. Web3Auth returns; the address bar in
  the header shows the restored wallet.
- **0:45–1:05** Enter a USDC sell amount. The Price ticker updates while
  typing (350 ms debounce). Tap Review to fire a firm Quote; call out
  `minBuyAmount`, `route`, `spender`, `chain`, and `destination` rows.
- **1:05–1:30** Confirm on the sheet. The biometric prompt gates signing.
  When needed, an exact-amount USDC approve is signed and broadcast. The
  Transaction Timeline advances through Authenticating → Approving →
  Approval submitted → Swapping → Submitted → Confirmed.
- **1:30–1:45** Show the swap tx hash and open Base scan in the browser.
  Return to the app; Portfolio reloads with the new balances.
- **1:45–2:00** Cut to a slide showing the repo map from
  `docs/architecture.md`, the test summary (`flutter test` + `pnpm test`
  numbers), and the security boundaries from `docs/security.md` (exact
  approvals, allowlisted spender/settler, receipt verification, audit
  disclaimer).
