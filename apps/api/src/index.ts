import { Hono } from 'hono';
import type { Bindings } from './env';
import { authRoutes } from './auth/routes';
import { marketRoutes } from './market/routes';
import { swapRoutes } from './swap/routes';

const app = new Hono<{ Bindings: Bindings }>();

app.get('/health', (context) => context.json({ status: 'ok' }));
app.route('/v1', authRoutes);
app.route('/v1', marketRoutes);
app.route('/v1', swapRoutes);

export default app;
