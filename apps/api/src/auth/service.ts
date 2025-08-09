import { SignJWT, jwtVerify } from 'jose';
import { generateNonce, SiweMessage } from 'siwe';

export type NonceStore = Map<string, number>;
export const createNonceStore = (): NonceStore => new Map();

export function consumeNonce(store: NonceStore, nonce: string, now: number) {
  const expiresAt = store.get(nonce);
  if (expiresAt == null || expiresAt < now) return false;
  store.delete(nonce);
  return true;
}

export function createChallenge() {
  return { nonce: generateNonce(), expiresAt: new Date(Date.now() + 300_000) };
}

const secret = (value: string) => new TextEncoder().encode(value);

export async function issueJwt(walletAddress: string, jwtSecret: string) {
  return new SignJWT({ walletAddress })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(walletAddress.toLowerCase())
    .setIssuedAt()
    .setExpirationTime('24h')
    .sign(secret(jwtSecret));
}

export async function verifyJwt(token: string, jwtSecret: string) {
  return jwtVerify(token, secret(jwtSecret));
}

export async function verifySiwe(input: {
  message: string;
  signature: string;
  nonce: string;
  domain: string;
  uri: string;
}) {
  const message = new SiweMessage(input.message);
  const result = await message.verify({
    signature: input.signature,
    nonce: input.nonce,
    domain: input.domain,
  });
  if (result.data.uri !== input.uri || result.data.chainId !== 8453) {
    throw new Error('invalid_siwe_scope');
  }
  return result.data;
}
