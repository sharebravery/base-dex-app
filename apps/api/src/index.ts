import { Hono } from 'hono';
import type { Bindings } from './env';

const app = new Hono<{ Bindings: Bindings }>();

app.get('/health', (context) => context.json({ status: 'ok' }));

export default app;
