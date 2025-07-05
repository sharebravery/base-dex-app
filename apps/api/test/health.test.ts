import { describe, expect, it } from 'vitest';
import app from '../src/index';

describe('GET /health', () => {
  it('returns a stable health contract', async () => {
    const response = await app.request('/health');
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ status: 'ok' });
  });
});
