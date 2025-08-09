import { createMiddleware } from 'hono/factory';
import type { Bindings } from '../env';
import { verifyJwt } from './service';

export type AuthVariables = { walletAddress: string };

export const requireAppSession = createMiddleware<{
  Bindings: Bindings;
  Variables: AuthVariables;
}>(async (context, next) => {
  const authorization = context.req.header('authorization');
  if (!authorization?.startsWith('Bearer ')) {
    return context.json({ error: 'unauthorized' }, 401);
  }
  try {
    const { payload } = await verifyJwt(
      authorization.slice('Bearer '.length),
      context.env.JWT_SECRET,
    );
    const walletAddress = payload.walletAddress;
    if (typeof walletAddress !== 'string') throw new Error('missing_wallet');
    context.set('walletAddress', walletAddress.toLowerCase());
    await next();
  } catch {
    return context.json({ error: 'unauthorized' }, 401);
  }
});
