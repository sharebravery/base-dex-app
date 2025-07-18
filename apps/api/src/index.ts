import { Hono } from 'hono';
import type { Bindings } from './env';
import { marketRoutes } from './market/routes';

const app = new Hono<{ Bindings: Bindings }>();

app.get('/health', (context) => context.json({ status: 'ok' }));
app.route('/v1', marketRoutes);

export default app;
