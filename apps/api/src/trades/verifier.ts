export type RpcLog = {
  address: string;
  topics: string[];
  data: string;
};

export type VerifiedDirection = {
  side: 'buy_eth' | 'sell_eth';
  usdcAmount: bigint;
};

const transferTopic =
  '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

function indexedAddress(topic: string) {
  return `0x${topic.slice(-40)}`.toLowerCase();
}

export function decodeUsdcDirection(input: {
  logs: RpcLog[];
  walletAddress: string;
  usdcAddress: string;
}): VerifiedDirection {
  const wallet = input.walletAddress.toLowerCase();
  const usdc = input.usdcAddress.toLowerCase();

  for (const log of input.logs) {
    if (log.address.toLowerCase() !== usdc) continue;
    if (log.topics[0]?.toLowerCase() !== transferTopic) continue;
    if (log.topics.length < 3) continue;

    const from = indexedAddress(log.topics[1]);
    const to = indexedAddress(log.topics[2]);
    const amount = BigInt(log.data);

    if (from === wallet && amount > 0n) {
      return { side: 'buy_eth', usdcAmount: amount };
    }
    if (to === wallet && amount > 0n) {
      return { side: 'sell_eth', usdcAmount: amount };
    }
  }

  throw new Error('missing_usdc_transfer');
}

export function validateVerifiedTrade(input: {
  chainId: number;
  status: number;
  from: string;
  to: string;
  authenticatedWallet: string;
  allowedSettler: string;
}) {
  if (input.chainId !== 8453) throw new Error('wrong_chain');
  if (input.status !== 1) throw new Error('failed_receipt');
  if (input.from.toLowerCase() !== input.authenticatedWallet.toLowerCase()) {
    throw new Error('sender_mismatch');
  }
  if (input.to.toLowerCase() !== input.allowedSettler.toLowerCase()) {
    throw new Error('unexpected_destination');
  }
}
