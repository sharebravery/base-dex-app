import { Hono } from 'hono';
import { cors } from 'hono/cors';
import type { Bindings } from './env';
import { authRoutes } from './auth/routes';
import { marketRoutes } from './market/routes';
import { swapRoutes } from './swap/routes';
import { profileRoutes } from './profile/routes';
import { tradeRoutes } from './trades/routes';

const app = new Hono<{ Bindings: Bindings }>();

/**
 * CORS is env-driven. `CORS_ORIGINS` is a comma-separated allowlist parsed once
 * per worker instance. In mock/dev we also add localhost defaults so a Flutter
 * web build hitting `flutter run -d chrome` at any random port works out of
 * the box — no config required until deployment.
 *
 * Requests carrying no Origin (native mobile / server-to-server / curl) are
 * always allowed; browser same-origin restrictions don't apply to them.
 */
app.use('*', async (context, next) => {
  const env = context.env ?? ({} as Bindings);
  const envOrigins = (env.CORS_ORIGINS ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  const isDev = env.APP_ENV !== 'production';
  return cors({
    origin: (origin) => {
      if (!origin) return origin; // non-browser client
      if (
        isDev &&
        (origin.startsWith('http://localhost:') ||
          origin.startsWith('http://127.0.0.1:') ||
          origin === 'http://localhost' ||
          origin === 'http://127.0.0.1')
      ) {
        return origin;
      }
      for (const allowed of envOrigins) {
        if (allowed === origin) return origin;
        if (allowed.includes('*')) {
          // `https://*.example.com` matches any single-subdomain host.
          // Escape regex metacharacters (but NOT `*` — we handle it after).
          const escaped = allowed
            .replace(/[.+?^${}()|[\]\\]/g, '\\$&')
            .replace(/\*/g, '[^.]+');
          if (new RegExp(`^${escaped}$`).test(origin)) return origin;
        }
      }
      return null;
    },
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowHeaders: ['content-type', 'authorization'],
    maxAge: 600,
  })(context, next);
});

app.get('/health', (context) => context.json({ status: 'ok' }));
app.route('/v1', authRoutes);
app.route('/v1', marketRoutes);
app.route('/v1', swapRoutes);
app.route('/v1', profileRoutes);
app.route('/v1', tradeRoutes);

export default app;