import { eq } from 'drizzle-orm';
import { Hono } from 'hono';
import { z } from 'zod';
import type { Bindings } from '../env';
import { withDb } from '../db/client';
import { profiles, userSettings, watchlists } from '../db/schema';
import { requireAppSession, type AuthVariables } from '../auth/middleware';

export const profileRoutes = new Hono<{
  Bindings: Bindings;
  Variables: AuthVariables;
}>();
profileRoutes.use('*', requireAppSession);

async function profileForWallet(env: Bindings, walletAddress: string) {
  return withDb(env, async (db) => {
    const rows = await db
      .select()
      .from(profiles)
      .where(eq(profiles.walletAddress, walletAddress))
      .limit(1);
    if (!rows[0]) throw new Error('profile_not_found');
    return rows[0];
  });
}

profileRoutes.get('/profile', async (context) => {
  const walletAddress = context.get('walletAddress');
  const profile = await profileForWallet(context.env, walletAddress);
  const settings = await withDb(context.env, (db) =>
    db
      .select()
      .from(userSettings)
      .where(eq(userSettings.profileId, profile.id))
      .limit(1),
  );
  return context.json({ walletAddress, settings: settings[0] });
});

export const settingsSchema = z.object({
  locale: z.enum(['en', 'zh']),
  appearance: z.enum(['system', 'light', 'dark']),
  displayCurrency: z.literal('USD'),
  preferBiometrics: z.boolean(),
});

profileRoutes.put('/settings', async (context) => {
  const body = settingsSchema.parse(await context.req.json());
  const profile = await profileForWallet(context.env, context.get('walletAddress'));
  await withDb(context.env, (db) =>
    db.update(userSettings).set(body).where(eq(userSettings.profileId, profile.id)),
  );
  return context.json(body);
});

profileRoutes.get('/watchlist', async (context) => {
  const profile = await profileForWallet(context.env, context.get('walletAddress'));
  const rows = await withDb(context.env, (db) =>
    db.select().from(watchlists).where(eq(watchlists.profileId, profile.id)),
  );
  return context.json({
    assetIds: rows
      .sort((a, b) => a.sortOrder - b.sortOrder)
      .map((row) => row.assetId),
  });
});

export const watchlistSchema = z.object({
  assetIds: z
    .array(
      z.enum([
        'ethereum',
        'bitcoin',
        'solana',
        'usd-coin',
        'aerodrome-finance',
        'degen-base',
      ]),
    )
    .max(10),
});

profileRoutes.put('/watchlist', async (context) => {
  const body = watchlistSchema.parse(await context.req.json());
  const profile = await profileForWallet(context.env, context.get('walletAddress'));
  await withDb(context.env, async (db) => {
    await db.delete(watchlists).where(eq(watchlists.profileId, profile.id));
    if (body.assetIds.length > 0) {
      await db.insert(watchlists).values(
        body.assetIds.map((assetId, index) => ({
          profileId: profile.id,
          assetId,
          sortOrder: index,
        })),
      );
    }
  });
  return context.json(body);
});
