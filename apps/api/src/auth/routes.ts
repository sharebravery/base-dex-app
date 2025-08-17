import { eq } from 'drizzle-orm';
import { Hono } from 'hono';
import { z } from 'zod';
import type { Bindings } from '../env';
import { withDb } from '../db/client';
import { profiles, siweNonces, userSettings } from '../db/schema';
import { createChallenge, issueJwt, verifySiwe } from './service';

export const authRoutes = new Hono<{ Bindings: Bindings }>();

const verifySchema = z.object({ message: z.string(), signature: z.string() });

authRoutes.post('/auth/challenge', async (context) => {
  const challenge = createChallenge();
  await withDb(context.env, (db) =>
    db.insert(siweNonces).values({
      nonce: challenge.nonce,
      expiresAt: challenge.expiresAt,
    }),
  );
  return context.json({
    nonce: challenge.nonce,
    expiresAt: challenge.expiresAt.toISOString(),
    domain: context.env.SIWE_DOMAIN,
    uri: context.env.SIWE_URI,
    chainId: 8453,
  });
});

authRoutes.post('/auth/verify', async (context) => {
  const body = verifySchema.parse(await context.req.json());
  const messageNonce = body.message.match(/Nonce: ([A-Za-z0-9]+)/)?.[1];
  if (!messageNonce) return context.json({ error: 'invalid_nonce' }, 400);

  const nonce = await withDb(context.env, async (db) => {
    const rows = await db
      .select()
      .from(siweNonces)
      .where(eq(siweNonces.nonce, messageNonce))
      .limit(1);
    const row = rows[0];
    if (!row || row.consumedAt || row.expiresAt < new Date()) return null;
    await db
      .update(siweNonces)
      .set({ consumedAt: new Date() })
      .where(eq(siweNonces.nonce, messageNonce));
    return row;
  });
  if (!nonce) return context.json({ error: 'invalid_nonce' }, 400);

  const verified = await verifySiwe({
    message: body.message,
    signature: body.signature,
    nonce: messageNonce,
    domain: context.env.SIWE_DOMAIN,
    uri: context.env.SIWE_URI,
  });
  const walletAddress = verified.address.toLowerCase();

  await withDb(context.env, async (db) => {
    const inserted = await db
      .insert(profiles)
      .values({ walletAddress })
      .onConflictDoNothing()
      .returning({ id: profiles.id });
    const profile = inserted[0] ?? (
      await db.select({ id: profiles.id }).from(profiles)
        .where(eq(profiles.walletAddress, walletAddress)).limit(1)
    )[0];
    await db.insert(userSettings).values({ profileId: profile.id })
      .onConflictDoNothing();
  });

  return context.json({
    token: await issueJwt(walletAddress, context.env.JWT_SECRET),
    expiresInSeconds: 86400,
    walletAddress,
  });
});
