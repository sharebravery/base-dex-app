# Flutter DEX Phase 3 — Trading and Transaction Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Track each checkbox and review each task before continuing.

**Goal:** Implement the real ETH/USDC Trade flow: indicative 0x Price, executable 0x Quote, device-authenticated exact Approve, Swap signing and broadcast, and restart-safe pending transaction tracking.

**Architecture:** The Worker validates and normalizes all 0x provider responses. Flutter owns user input state and transaction orchestration but signs only through `WalletService`. `TransactionService` validates chain, spender, and destinations before requesting a signature.

**Tech Stack:** Hono, Zod, 0x Swap API v2, Riverpod, Freezed, Dio, web3dart, local_auth, shared_preferences.

## Global Constraints

- Apply every constraint from the master plan.
- ETH/USDC is the only permitted pair.
- Editing calls `/price`; Review calls `/quote`.
- Quote freshness is `fetchedAt + validFor`, not a guessed provider expiry field.
- Exact Approve only; no unlimited approval.
- The 0x Swap transaction destination must never be used as the approval spender.
- Device authentication occurs once immediately before the execution sequence.
- Persist only non-sensitive pending metadata.

---

### Task 8: Add 0x Price, Quote, and Trade State

**Files:**
- Create: `apps/api/src/swap/schema.ts`
- Create: `apps/api/src/swap/client.ts`
- Create: `apps/api/src/swap/routes.ts`
- Modify: `apps/api/src/env.ts`
- Modify: `apps/api/src/index.ts`
- Create: `apps/api/test/swap.test.ts`
- Create: `apps/mobile/lib/features/trade/trade_models.dart`
- Create: `apps/mobile/lib/features/trade/swap_repository.dart`
- Create: `apps/mobile/lib/features/trade/trade_controller.dart`
- Create: `apps/mobile/lib/features/trade/trade_screen.dart`
- Test: `apps/mobile/test/features/trade/trade_controller_test.dart`
- Test: `apps/mobile/test/features/trade/swap_repository_test.dart`

**Interfaces:**
- Consumes: active wallet address, ETH/USDC token registry, Dio API client.
- Produces: `POST /v1/swap/price`, `POST /v1/swap/quote`, `SwapPrice`, `SwapQuote`, `TradeState`, `SwapRepository`.

- [ ] **Step 1: Write Worker validation tests**

Create `apps/api/test/swap.test.ts`:

```ts
import { afterEach, describe, expect, it, vi } from 'vitest';
import app from '../src/index';

const env = {
  APP_ENV: 'mock' as const,
  MARKET_API_BASE_URL: 'https://market.test',
  ZEROX_API_BASE_URL: 'https://api.0x.org',
  ZEROX_API_KEY: 'test-key',
  ZEROX_ALLOWANCE_HOLDER: '0x0000000000000000000000000000000000000001',
  ZEROX_SETTLER: '0x0000000000000000000000000000000000000002',
};

afterEach(() => vi.restoreAllMocks());

describe('swap proxy', () => {
  it('rejects a non-curated pair before provider access', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch');
    const response = await app.request('/v1/swap/price', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chainId: 8453,
        sellToken: '0x0000000000000000000000000000000000009999',
        buyToken: '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913',
        sellAmount: '1000000',
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      }),
    }, env);
    expect(response.status).toBe(400);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('normalizes a firm quote and validates spender', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(new Response(JSON.stringify({
      buyAmount: '300000000000000',
      minBuyAmount: '298500000000000',
      sellAmount: '1000000',
      totalNetworkFee: '10000000000000',
      issues: { allowance: { spender: env.ZEROX_ALLOWANCE_HOLDER } },
      transaction: {
        to: env.ZEROX_SETTLER,
        data: '0x1234',
        value: '0',
        gas: '220000',
        gasPrice: '1000000'
      },
      route: { fills: [{ source: 'Uniswap_V3' }] }
    }), { status: 200 }));

    const response = await app.request('/v1/swap/quote', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chainId: 8453,
        sellToken: '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913',
        buyToken: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
        sellAmount: '1000000',
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      }),
    }, env);

    expect(response.status).toBe(200);
    const json = await response.json() as Record<string, unknown>;
    expect(json.allowanceTarget).toBe(env.ZEROX_ALLOWANCE_HOLDER);
    expect(json.transactionTo).toBe(env.ZEROX_SETTLER);
  });
});
```

- [ ] **Step 2: Run Worker test and verify red state**

```bash
cd apps/api
npm test -- swap.test.ts
```

Expected: missing swap routes.

- [ ] **Step 3: Implement request and provider schemas**

Extend `apps/api/src/env.ts`:

```ts
ZEROX_API_BASE_URL: string;
ZEROX_API_KEY: string;
ZEROX_ALLOWANCE_HOLDER: string;
ZEROX_SETTLER: string;
```

Create `apps/api/src/swap/schema.ts`:

```ts
import { z } from 'zod';

const address = z.string().regex(/^0x[a-fA-F0-9]{40}$/);
const uintString = z.string().regex(/^\d+$/).refine((value) => BigInt(value) > 0n);

export const swapRequestSchema = z.object({
  chainId: z.literal(8453),
  sellToken: address,
  buyToken: address,
  sellAmount: uintString,
  taker: address,
  slippageBps: z.number().int().min(10).max(300),
});

export const providerQuoteSchema = z.object({
  buyAmount: z.string(),
  minBuyAmount: z.string().optional(),
  sellAmount: z.string(),
  totalNetworkFee: z.string().optional().default('0'),
  issues: z.object({
    allowance: z.object({ spender: address }).nullable().optional(),
  }).optional(),
  transaction: z.object({
    to: address,
    data: z.string().regex(/^0x[a-fA-F0-9]*$/),
    value: z.string(),
    gas: z.string(),
    gasPrice: z.string().optional(),
  }).optional(),
  route: z.object({
    fills: z.array(z.object({ source: z.string() })).default([]),
  }).optional(),
});
```

- [ ] **Step 4: Implement 0x client and routes**

Create `apps/api/src/swap/client.ts`:

```ts
import type { Bindings } from '../env';
import { providerQuoteSchema } from './schema';

const ETH = '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
const USDC = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913';

export type SwapInput = {
  chainId: 8453;
  sellToken: string;
  buyToken: string;
  sellAmount: string;
  taker: string;
  slippageBps: number;
};

export function assertCuratedPair(input: SwapInput) {
  const sell = input.sellToken.toLowerCase();
  const buy = input.buyToken.toLowerCase();
  const permitted = (sell === ETH && buy === USDC) || (sell === USDC && buy === ETH);
  if (!permitted) throw new Error('unsupported_pair');
}

export async function requestZeroX(
  env: Bindings,
  kind: 'price' | 'quote',
  input: SwapInput,
) {
  assertCuratedPair(input);
  const url = new URL(`/swap/allowance-holder/${kind}`, env.ZEROX_API_BASE_URL);
  for (const [key, value] of Object.entries({
    chainId: String(input.chainId),
    sellToken: input.sellToken,
    buyToken: input.buyToken,
    sellAmount: input.sellAmount,
    taker: input.taker,
    slippageBps: String(input.slippageBps),
  })) url.searchParams.set(key, value);

  const response = await fetch(url, {
    headers: { '0x-api-key': env.ZEROX_API_KEY, '0x-version': 'v2' },
  });
  if (!response.ok) throw new Error(`zero_x_${response.status}`);
  return providerQuoteSchema.parse(await response.json());
}
```

Create `apps/api/src/swap/routes.ts`:

```ts
import { Hono } from 'hono';
import type { Bindings } from '../env';
import { requestZeroX } from './client';
import { swapRequestSchema } from './schema';

export const swapRoutes = new Hono<{ Bindings: Bindings }>();

function normalize(
  kind: 'price' | 'quote',
  env: Bindings,
  provider: Awaited<ReturnType<typeof requestZeroX>>,
) {
  const allowanceTarget = provider.issues?.allowance?.spender;
  if (allowanceTarget && allowanceTarget.toLowerCase() !== env.ZEROX_ALLOWANCE_HOLDER.toLowerCase()) {
    throw new Error('unexpected_allowance_target');
  }
  if (kind === 'quote') {
    if (!provider.transaction) throw new Error('missing_transaction');
    if (provider.transaction.to.toLowerCase() !== env.ZEROX_SETTLER.toLowerCase()) {
      throw new Error('unexpected_transaction_target');
    }
  }
  return {
    sellAmount: provider.sellAmount,
    buyAmount: provider.buyAmount,
    minBuyAmount: provider.minBuyAmount ?? provider.buyAmount,
    networkFee: provider.totalNetworkFee,
    allowanceTarget: allowanceTarget ?? null,
    transactionTo: provider.transaction?.to ?? null,
    transactionData: provider.transaction?.data ?? null,
    transactionValue: provider.transaction?.value ?? '0',
    gas: provider.transaction?.gas ?? '0',
    gasPrice: provider.transaction?.gasPrice ?? '0',
    routeLabels: provider.route?.fills.map((fill) => fill.source) ?? [],
    fetchedAt: new Date().toISOString(),
    validForSeconds: kind === 'quote' ? 15 : 10,
  };
}

for (const kind of ['price', 'quote'] as const) {
  swapRoutes.post(`/swap/${kind}`, async (context) => {
    try {
      const input = swapRequestSchema.parse(await context.req.json());
      const provider = await requestZeroX(context.env, kind, input);
      return context.json(normalize(kind, context.env, provider));
    } catch (error) {
      const message = error instanceof Error ? error.message : 'invalid_request';
      return context.json({ error: message }, 400);
    }
  });
}
```

Mount with `app.route('/v1', swapRoutes)`.

- [ ] **Step 5: Write Flutter Trade state tests**

Create `apps/mobile/test/features/trade/trade_controller_test.dart`:

```dart
import 'package:decimal/decimal.dart';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/trade_controller.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/features/trade/swap_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeSwapRepository implements SwapRepository {
  int priceCalls = 0;
  int quoteCalls = 0;

  @override
  Future<SwapPrice> getPrice(SwapRequest request) async {
    priceCalls++;
    return SwapPrice(
      sellAmount: request.sellAmount,
      buyAmount: BigInt.from(300),
      networkFee: BigInt.one,
      fetchedAt: DateTime.utc(2026),
      validFor: const Duration(seconds: 10),
    );
  }

  @override
  Future<SwapQuote> getQuote(SwapRequest request) async {
    quoteCalls++;
    return SwapQuote(
      sellAmount: request.sellAmount,
      buyAmount: BigInt.from(300),
      minBuyAmount: BigInt.from(298),
      networkFee: BigInt.one,
      allowanceTarget: '0x0000000000000000000000000000000000000001',
      transactionTo: '0x0000000000000000000000000000000000000002',
      transactionData: '0x1234',
      transactionValue: BigInt.zero,
      gas: BigInt.from(220000),
      gasPrice: BigInt.one,
      routeLabels: const ['Uniswap_V3'],
      fetchedAt: DateTime.utc(2026),
      validFor: const Duration(seconds: 15),
    );
  }
}

void main() {
  test('editing requests Price and Review requests Quote', () async {
    final repository = FakeSwapRepository();
    final controller = TradeController(repository);
    await controller.updateAmount(
      amountText: '1',
      sellToken: BaseTokens.usdc,
      buyToken: BaseTokens.eth,
      taker: '0x1111111111111111111111111111111111111111',
    );
    expect(repository.priceCalls, 1);
    expect(repository.quoteCalls, 0);
    await controller.review();
    expect(repository.quoteCalls, 1);
  });
}
```

- [ ] **Step 6: Implement Freezed Trade models**

Create `apps/mobile/lib/features/trade/trade_models.dart`:

```dart
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'trade_models.freezed.dart';

final class SwapRequest {
  const SwapRequest({
    required this.sellToken,
    required this.buyToken,
    required this.sellAmount,
    required this.taker,
    required this.slippageBps,
  });
  final TokenInfo sellToken;
  final TokenInfo buyToken;
  final BigInt sellAmount;
  final String taker;
  final int slippageBps;
}

@freezed
abstract class SwapPrice with _$SwapPrice {
  const factory SwapPrice({
    required BigInt sellAmount,
    required BigInt buyAmount,
    required BigInt networkFee,
    required DateTime fetchedAt,
    required Duration validFor,
  }) = _SwapPrice;
}

@freezed
abstract class SwapQuote with _$SwapQuote {
  const SwapQuote._();
  const factory SwapQuote({
    required BigInt sellAmount,
    required BigInt buyAmount,
    required BigInt minBuyAmount,
    required BigInt networkFee,
    required String? allowanceTarget,
    required String transactionTo,
    required String transactionData,
    required BigInt transactionValue,
    required BigInt gas,
    required BigInt gasPrice,
    required List<String> routeLabels,
    required DateTime fetchedAt,
    required Duration validFor,
  }) = _SwapQuote;

  bool isFreshAt(DateTime now) => now.isBefore(fetchedAt.add(validFor));
}

@freezed
abstract class TradeState with _$TradeState {
  const factory TradeState({
    @Default('') String amountText,
    @Default(50) int slippageBps,
    SwapRequest? request,
    SwapPrice? price,
    SwapQuote? quote,
    @Default(false) bool loadingPrice,
    @Default(false) bool loadingQuote,
    String? errorCode,
  }) = _TradeState;
}
```

- [ ] **Step 7: Implement repository and controller**

Create `apps/mobile/lib/features/trade/swap_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:dex_app/features/trade/trade_models.dart';

abstract interface class SwapRepository {
  Future<SwapPrice> getPrice(SwapRequest request);
  Future<SwapQuote> getQuote(SwapRequest request);
}

final class ApiSwapRepository implements SwapRepository {
  ApiSwapRepository(this._dio);
  final Dio _dio;

  Map<String, Object> _body(SwapRequest request) => {
        'chainId': 8453,
        'sellToken': request.sellToken.address,
        'buyToken': request.buyToken.address,
        'sellAmount': request.sellAmount.toString(),
        'taker': request.taker,
        'slippageBps': request.slippageBps,
      };

  @override
  Future<SwapPrice> getPrice(SwapRequest request) async {
    final response = await _dio.post<Map<String, Object?>>('/v1/swap/price', data: _body(request));
    final json = response.data!;
    return SwapPrice(
      sellAmount: BigInt.parse(json['sellAmount']! as String),
      buyAmount: BigInt.parse(json['buyAmount']! as String),
      networkFee: BigInt.parse(json['networkFee']! as String),
      fetchedAt: DateTime.parse(json['fetchedAt']! as String),
      validFor: Duration(seconds: json['validForSeconds']! as int),
    );
  }

  @override
  Future<SwapQuote> getQuote(SwapRequest request) async {
    final response = await _dio.post<Map<String, Object?>>('/v1/swap/quote', data: _body(request));
    final json = response.data!;
    return SwapQuote(
      sellAmount: BigInt.parse(json['sellAmount']! as String),
      buyAmount: BigInt.parse(json['buyAmount']! as String),
      minBuyAmount: BigInt.parse(json['minBuyAmount']! as String),
      networkFee: BigInt.parse(json['networkFee']! as String),
      allowanceTarget: json['allowanceTarget'] as String?,
      transactionTo: json['transactionTo']! as String,
      transactionData: json['transactionData']! as String,
      transactionValue: BigInt.parse(json['transactionValue']! as String),
      gas: BigInt.parse(json['gas']! as String),
      gasPrice: BigInt.parse(json['gasPrice']! as String),
      routeLabels: (json['routeLabels']! as List<Object?>).cast<String>(),
      fetchedAt: DateTime.parse(json['fetchedAt']! as String),
      validFor: Duration(seconds: json['validForSeconds']! as int),
    );
  }
}
```

Create `apps/mobile/lib/features/trade/trade_controller.dart`:

```dart
import 'dart:async';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/swap_repository.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:flutter/foundation.dart';

final class TradeController extends ChangeNotifier {
  TradeController(this._repository);
  final SwapRepository _repository;
  TradeState state = const TradeState();
  Timer? _debounce;

  Future<void> updateAmount({
    required String amountText,
    required TokenInfo sellToken,
    required TokenInfo buyToken,
    required String taker,
  }) async {
    _debounce?.cancel();
    final amount = BigInt.tryParse(amountText);
    if (amount == null || amount <= BigInt.zero) {
      state = state.copyWith(
        amountText: amountText,
        request: null,
        price: null,
        quote: null,
        loadingPrice: false,
      );
      notifyListeners();
      return;
    }

    final request = SwapRequest(
      sellToken: sellToken,
      buyToken: buyToken,
      sellAmount: amount,
      taker: taker,
      slippageBps: state.slippageBps,
    );
    state = state.copyWith(
      amountText: amountText,
      request: request,
      loadingPrice: true,
      quote: null,
      errorCode: null,
    );
    notifyListeners();

    final completer = Completer<void>();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final price = await _repository.getPrice(request);
        if (state.request == request) {
          state = state.copyWith(price: price, loadingPrice: false);
          notifyListeners();
        }
      } catch (_) {
        state = state.copyWith(
          loadingPrice: false,
          errorCode: 'price_unavailable',
        );
        notifyListeners();
      } finally {
        completer.complete();
      }
    });
    await completer.future;
  }

  Future<void> review() async {
    final request = state.request;
    if (request == null) throw StateError('No valid request');
    state = state.copyWith(loadingQuote: true, errorCode: null);
    notifyListeners();
    try {
      final quote = await _repository.getQuote(request);
      state = state.copyWith(quote: quote, loadingQuote: false);
    } catch (_) {
      state = state.copyWith(
        loadingQuote: false,
        errorCode: 'quote_unavailable',
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 8: Build Trade screen and verify**

Create `apps/mobile/lib/features/trade/trade_screen.dart`:

```dart
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/trade_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TradeScreen extends HookWidget {
  const TradeScreen({
    required this.controller,
    required this.taker,
    required this.onConfirm,
    super.key,
  });

  final TradeController controller;
  final String taker;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final amountController = useTextEditingController();
    useEffect(() {
      void listener() {
        controller.updateAmount(
          amountText: amountController.text,
          sellToken: BaseTokens.usdc,
          buyToken: BaseTokens.eth,
          taker: taker,
        );
      }
      amountController.addListener(listener);
      return () => amountController.removeListener(listener);
    }, [amountController, controller, taker]);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final state = controller.state;
        final quoteFresh =
            state.quote?.isFreshAt(DateTime.now()) == true;
        final form = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'USDC base units',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.loadingPrice
                    ? 'Loading Price…'
                    : state.price == null
                        ? 'Enter amount'
                        : 'Indicative: ${state.price!.buyAmount}',
              ),
              if (state.errorCode != null) ...[
                const SizedBox(height: 8),
                Text(state.errorCode!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: state.request == null || state.loadingQuote
                    ? null
                    : controller.review,
                child: Text(state.loadingQuote ? 'Loading Quote…' : 'Review'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: quoteFresh ? onConfirm : null,
                child: const Text('Confirm Swap'),
              ),
            ],
          ),
        );

        return Scaffold(
          appBar: AppBar(title: const Text('ETH / USDC')),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 840) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: form,
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Expanded(child: Placeholder()),
                      const SizedBox(width: 24),
                      form,
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
```

Run:

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/features/trade
cd ../api
npm run typecheck
npm test -- swap.test.ts
```

Expected: all tests pass.

- [ ] **Step 9: Commit**

```bash
git add apps
git commit -m "feat: add 0x price and quote flow"
```

---

### Task 9: Execute Exact Approve and Swap

**Files:**
- Create: `apps/mobile/lib/core/security/biometric_gate.dart`
- Create: `apps/mobile/lib/features/trade/transaction_service.dart`
- Create: `apps/mobile/lib/features/trade/trade_executor.dart`
- Create: `apps/mobile/lib/features/trade/confirmation_sheet.dart`
- Create: `apps/mobile/lib/features/trade/transaction_timeline.dart`
- Test: `apps/mobile/test/features/trade/trade_executor_test.dart`
- Test: `apps/mobile/test/features/trade/confirmation_sheet_test.dart`

**Interfaces:**
- Consumes: `WalletService`, `SwapQuote`, `EvmRpc`, active wallet address.
- Produces: `BiometricGate`, `TransactionService`, `TradeExecutor`, `TransactionStage`, `TradeExecutionResult`.

- [ ] **Step 1: Write execution-order tests**

Create `apps/mobile/test/features/trade/trade_executor_test.dart`:

```dart
import 'package:dex_app/core/security/biometric_gate.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:dex_app/features/trade/trade_executor.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/features/trade/transaction_service.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeBiometricGate implements BiometricGate {
  FakeBiometricGate(this.log, {this.result = true});
  final List<String> log;
  final bool result;

  @override
  Future<bool> authenticate(String reason) async {
    log.add('authenticate');
    return result;
  }
}

final class FakeWalletService implements WalletService {
  FakeWalletService(this.log);
  final List<String> log;

  @override
  Future<WalletSession?> restoreSession() async => null;
  @override
  Future<WalletSession> login(WalletLoginMethod method) => throw UnimplementedError();
  @override
  Future<String> signMessage(String message) => throw UnimplementedError();
  @override
  Future<void> logout() async {}

  @override
  Future<String> signTransaction(EvmTransactionRequest request) async {
    log.add(request.data.startsWith('0x095ea7b3') ? 'signApprove' : 'signSwap');
    return request.data;
  }
}

final class FakeChainGateway implements ChainGateway {
  FakeChainGateway(this.log, {required this.currentAllowance});
  final List<String> log;
  final BigInt currentAllowance;

  @override
  Future<BigInt> allowance(String owner, String token, String spender) async {
    log.add('readAllowance');
    return currentAllowance;
  }

  @override
  Future<int> nonce(String address) async => 1;

  @override
  Future<String> broadcast(String signedTransaction) async {
    final approval = signedTransaction.startsWith('0x095ea7b3');
    log.add(approval ? 'approve:1000000' : 'swap');
    return approval ? '0xapproval' : '0xswap';
  }

  @override
  Future<void> waitForSuccess(String txHash) async {
    log.add('waitApproval');
  }
}

SwapQuote quote(BigInt sellAmount) => SwapQuote(
      sellAmount: sellAmount,
      buyAmount: BigInt.from(300),
      minBuyAmount: BigInt.from(298),
      networkFee: BigInt.one,
      allowanceTarget: '0x0000000000000000000000000000000000000001',
      transactionTo: '0x0000000000000000000000000000000000000002',
      transactionData: '0x1234',
      transactionValue: BigInt.zero,
      gas: BigInt.from(220000),
      gasPrice: BigInt.one,
      routeLabels: const ['Uniswap_V3'],
      fetchedAt: DateTime.now(),
      validFor: const Duration(minutes: 1),
    );

TradeExecutor executor({
  required List<String> log,
  required BigInt allowance,
  bool authenticated = true,
}) {
  final chain = FakeChainGateway(log, currentAllowance: allowance);
  final service = TransactionService(
    wallet: FakeWalletService(log),
    chain: chain,
    allowedSpender: '0x0000000000000000000000000000000000000001',
    allowedSettler: '0x0000000000000000000000000000000000000002',
  );
  return TradeExecutor(
    biometric: FakeBiometricGate(log, result: authenticated),
    transactions: service,
    chain: chain,
    owner: '0x1111111111111111111111111111111111111111',
    sellToken: '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913',
  );
}

void main() {
  test('insufficient USDC allowance approves exact amount before Swap', () async {
    final log = <String>[];
    await executor(log: log, allowance: BigInt.zero)
        .execute(quote(BigInt.from(1000000)));
    expect(log, [
      'authenticate',
      'readAllowance',
      'signApprove',
      'approve:1000000',
      'waitApproval',
      'signSwap',
      'swap',
    ]);
  });

  test('rejected device authentication performs no signing', () async {
    final log = <String>[];
    await expectLater(
      executor(log: log, allowance: BigInt.zero, authenticated: false)
          .execute(quote(BigInt.one)),
      throwsA(isA<TradeExecutionCancelled>()),
    );
    expect(log, ['authenticate']);
  });
}
```

- [ ] **Step 2: Run test and verify red state**

```bash
flutter test test/features/trade/trade_executor_test.dart
```

Expected: missing executor.

- [ ] **Step 3: Implement device-auth boundary**

Add dependency:

```bash
flutter pub add local_auth
```

Create `apps/mobile/lib/core/security/biometric_gate.dart`:

```dart
import 'package:local_auth/local_auth.dart';

abstract interface class BiometricGate {
  Future<bool> authenticate(String reason);
}

final class LocalAuthBiometricGate implements BiometricGate {
  LocalAuthBiometricGate(this._localAuth);
  final LocalAuthentication _localAuth;

  @override
  Future<bool> authenticate(String reason) => _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
}
```

- [ ] **Step 4: Implement transaction boundary with exact approval**

Create `apps/mobile/lib/features/trade/transaction_service.dart`:

```dart
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:dex_app/features/trade/trade_models.dart';

abstract interface class ChainGateway {
  Future<BigInt> allowance(String owner, String token, String spender);
  Future<int> nonce(String address);
  Future<String> broadcast(String signedTransaction);
  Future<void> waitForSuccess(String txHash);
}

final class TransactionService {
  TransactionService({
    required this.wallet,
    required this.chain,
    required this.allowedSpender,
    required this.allowedSettler,
  });

  final WalletService wallet;
  final ChainGateway chain;
  final String allowedSpender;
  final String allowedSettler;

  Future<String> approveExact({
    required String owner,
    required String token,
    required String spender,
    required BigInt amount,
  }) async {
    if (spender.toLowerCase() != allowedSpender.toLowerCase()) {
      throw StateError('Unexpected approval spender');
    }
    final request = EvmTransactionRequest(
      to: token,
      data: encodeApprove(spender, amount),
      value: BigInt.zero,
      gasLimit: BigInt.from(100000),
      maxFeePerGas: BigInt.from(1),
      maxPriorityFeePerGas: BigInt.from(1),
      nonce: await chain.nonce(owner),
      chainId: 8453,
    );
    return chain.broadcast(await wallet.signTransaction(request));
  }

  Future<String> swap({required String owner, required SwapQuote quote}) async {
    if (quote.transactionTo.toLowerCase() != allowedSettler.toLowerCase()) {
      throw StateError('Unexpected Swap destination');
    }
    final request = EvmTransactionRequest(
      to: quote.transactionTo,
      data: quote.transactionData,
      value: quote.transactionValue,
      gasLimit: quote.gas,
      maxFeePerGas: quote.gasPrice,
      maxPriorityFeePerGas: BigInt.zero,
      nonce: await chain.nonce(owner),
      chainId: 8453,
    );
    return chain.broadcast(await wallet.signTransaction(request));
  }
}

String encodeApprove(String spender, BigInt amount) {
  final selector = '095ea7b3';
  final address = spender.toLowerCase().replaceFirst('0x', '').padLeft(64, '0');
  final value = amount.toRadixString(16).padLeft(64, '0');
  return '0x$selector$address$value';
}
```

- [ ] **Step 5: Implement execution state machine**

Create `apps/mobile/lib/features/trade/trade_executor.dart`:

```dart
import 'package:dex_app/core/security/biometric_gate.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/features/trade/transaction_service.dart';

class TradeExecutionCancelled implements Exception {}

enum TransactionStage {
  preparing,
  authenticating,
  approving,
  approvalSubmitted,
  swapping,
  submitted,
  confirmed,
  failed,
}

final class TradeExecutionResult {
  const TradeExecutionResult({this.approvalTxHash, required this.swapTxHash});
  final String? approvalTxHash;
  final String swapTxHash;
}

final class TradeExecutor {
  TradeExecutor({
    required this.biometric,
    required this.transactions,
    required this.chain,
    required this.owner,
    required this.sellToken,
  });

  final BiometricGate biometric;
  final TransactionService transactions;
  final ChainGateway chain;
  final String owner;
  final String sellToken;

  Future<TradeExecutionResult> execute(SwapQuote quote) async {
    if (!quote.isFreshAt(DateTime.now())) throw StateError('Quote expired');
    if (!await biometric.authenticate('Confirm on-chain transaction')) {
      throw TradeExecutionCancelled();
    }

    String? approvalHash;
    final spender = quote.allowanceTarget;
    if (spender != null) {
      final current = await chain.allowance(owner, sellToken, spender);
      if (current < quote.sellAmount) {
        approvalHash = await transactions.approveExact(
          owner: owner,
          token: sellToken,
          spender: spender,
          amount: quote.sellAmount,
        );
        await chain.waitForSuccess(approvalHash);
      }
    }

    final swapHash = await transactions.swap(owner: owner, quote: quote);
    return TradeExecutionResult(approvalTxHash: approvalHash, swapTxHash: swapHash);
  }

  // Test-only constructors belong in the test file, not production code.
}
```

Update the test to use explicit fake implementations of `BiometricGate`, `ChainGateway`, and `TransactionService`; do not add fake constructors to production code.

- [ ] **Step 6: Implement confirmation and timeline UI**

Create `confirmation_sheet.dart` that receives an immutable `SwapQuote` and displays Pay, Receive, Minimum Received, Network Fee, Slippage, Route, Spender, chain `Base`, and destination. Its Confirm callback is disabled when the Quote is stale.

Create `transaction_timeline.dart` with a `switch` over every `TransactionStage`; use `AnimatedSwitcher` so the confirmation content becomes the timeline without dismissing the sheet.

The widget test must assert that a USDC sell with an allowance target shows both `Approve USDC` and the exact approval amount.

- [ ] **Step 7: Verify and commit**

```bash
flutter analyze
flutter test test/features/trade

git add apps/mobile
git commit -m "feat: execute exact approve and swap"
```

---

### Task 10: Persist and Recover Pending Transactions

**Files:**
- Create: `apps/mobile/lib/features/trade/pending_transaction.dart`
- Create: `apps/mobile/lib/features/trade/pending_transaction_store.dart`
- Create: `apps/mobile/lib/features/trade/transaction_tracker.dart`
- Modify: `apps/mobile/lib/main.dart`
- Test: `apps/mobile/test/features/trade/pending_transaction_store_test.dart`
- Test: `apps/mobile/test/features/trade/transaction_tracker_test.dart`

**Interfaces:**
- Consumes: Tx Hashes from `TradeExecutionResult`, receipt lookup through `ChainGateway`.
- Produces: `PendingTransaction`, `PendingTransactionStore`, `TransactionTracker.resume()`.

- [ ] **Step 1: Write persistence and recovery tests**

Create `apps/mobile/test/features/trade/pending_transaction_store_test.dart`:

```dart
import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores only non-sensitive pending metadata', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PendingTransactionStore(SharedPreferencesAsync());
    final pending = PendingTransaction(
      txHash: '0xabc',
      walletAddress: '0x1111111111111111111111111111111111111111',
      operation: PendingOperation.swap,
      symbol: 'ETH/USDC',
      createdAt: DateTime.utc(2026),
    );
    await store.save(pending);
    expect(await store.loadAll(), [pending]);
  });
}
```

Create `apps/mobile/test/features/trade/transaction_tracker_test.dart` with a fake receipt source that returns pending once and confirmed next; assert the store entry remains after pending and is removed after confirmation.

- [ ] **Step 2: Run tests and verify red state**

```bash
flutter pub add shared_preferences
flutter test test/features/trade/pending_transaction_store_test.dart test/features/trade/transaction_tracker_test.dart
```

Expected: missing pending types.

- [ ] **Step 3: Implement immutable pending model**

Create `apps/mobile/lib/features/trade/pending_transaction.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'pending_transaction.freezed.dart';
part 'pending_transaction.g.dart';

enum PendingOperation { approve, swap, withdraw }

@freezed
abstract class PendingTransaction with _$PendingTransaction {
  const factory PendingTransaction({
    required String txHash,
    required String walletAddress,
    required PendingOperation operation,
    required String symbol,
    required DateTime createdAt,
  }) = _PendingTransaction;

  factory PendingTransaction.fromJson(Map<String, Object?> json) =>
      _$PendingTransactionFromJson(json);
}
```

- [ ] **Step 4: Implement non-sensitive store**

Create `apps/mobile/lib/features/trade/pending_transaction_store.dart`:

```dart
import 'dart:convert';
import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class PendingTransactionStore {
  PendingTransactionStore(this._preferences);
  final SharedPreferencesAsync _preferences;
  static const _key = 'pending_transactions_v1';

  Future<List<PendingTransaction>> loadAll() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<Object?>;
    return list
        .map((item) => PendingTransaction.fromJson(item! as Map<String, Object?>))
        .toList(growable: false);
  }

  Future<void> save(PendingTransaction value) async {
    final current = await loadAll();
    final next = [
      ...current.where((item) => item.txHash != value.txHash),
      value,
    ];
    await _preferences.setString(
      _key,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> remove(String txHash) async {
    final next = (await loadAll()).where((item) => item.txHash != txHash).toList();
    await _preferences.setString(
      _key,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }
}
```

- [ ] **Step 5: Implement receipt tracker with bounded polling**

Create `apps/mobile/lib/features/trade/transaction_tracker.dart`:

```dart
import 'dart:async';
import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';

enum ReceiptState { pending, confirmed, reverted }

abstract interface class ReceiptSource {
  Future<ReceiptState> receiptState(String txHash);
}

final class TransactionTracker {
  TransactionTracker(this._store, this._source);
  final PendingTransactionStore _store;
  final ReceiptSource _source;

  static const intervals = [
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 8),
    Duration(seconds: 13),
    Duration(seconds: 20),
  ];

  Future<ReceiptState> track(PendingTransaction transaction) async {
    for (final interval in intervals) {
      final state = await _source.receiptState(transaction.txHash);
      if (state != ReceiptState.pending) {
        await _store.remove(transaction.txHash);
        return state;
      }
      await Future<void>.delayed(interval);
    }
    return ReceiptState.pending;
  }

  Future<void> resumeForWallet(String walletAddress) async {
    final pending = (await _store.loadAll()).where(
      (item) => item.walletAddress.toLowerCase() == walletAddress.toLowerCase(),
    );
    for (final item in pending) {
      unawaited(track(item));
    }
  }
}
```

- [ ] **Step 6: Restore after wallet and app session restoration**

In the startup controller called by `main.dart`, enforce this order:

```dart
final walletSession = await authController.restore();
if (walletSession != null) {
  await appSessionController.restoreOrSignIn(walletSession);
  await transactionTracker.resumeForWallet(walletSession.address);
}
```

Do not place asynchronous orchestration directly in a Widget build method.

- [ ] **Step 7: Generate, verify, and commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/features/trade

git add apps/mobile
git commit -m "feat: recover pending transactions after restart"
```

---

## Phase 3 Checkpoint

```bash
cd apps/mobile
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
cd ../api
npm ci
npm run typecheck
npm test
```

Expected: every command exits `0`. Complete one controlled staging Quote and inspect spender/destination values before Phase 4.
