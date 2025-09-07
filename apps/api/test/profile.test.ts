import { describe, expect, it } from 'vitest';
import { settingsSchema, watchlistSchema } from '../src/profile/routes';

describe('profile input schemas', () => {
  it('rejects unsupported locale values', () => {
    expect(() => settingsSchema.parse({
      locale: 'fr',
      appearance: 'system',
      displayCurrency: 'USD',
      preferBiometrics: true,
    })).toThrow();
  });

  it('accepts Simplified Chinese settings', () => {
    expect(settingsSchema.parse({
      locale: 'zh',
      appearance: 'dark',
      displayCurrency: 'USD',
      preferBiometrics: true,
    }).locale).toBe('zh');
  });

  it('rejects non-catalog watchlist assets', () => {
    expect(() => watchlistSchema.parse({ assetIds: ['unknown-token'] })).toThrow();
  });
});
