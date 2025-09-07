import { Hono } from 'hono';
import type { Bindings } from './env';
import { authRoutes } from './auth/routes';
import { marketRoutes } from './market/routes';
import { swapRoutes } from './swap/routes';
import { profileRoutes } from './profile/routes';
import { tradeRoutes } from './trades/routes';

const app = new Hono<{ Bindings: Bindings }>();

app.get('/health', (context) => context.json({ status: 'ok' }));
app.route('/v1', authRoutes);
app.route('/v1', marketRoutes);
app.route('/v1', swapRoutes);
app.route('/v1', profileRoutes);
app.route('/v1', tradeRoutes);

export default app;
