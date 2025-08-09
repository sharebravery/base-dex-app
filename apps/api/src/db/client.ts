import { drizzle, type NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Client } from 'pg';
import type { Bindings } from '../env';
import * as schema from './schema';

export async function withDb<T>(
  env: Bindings,
  operation: (db: NodePgDatabase<typeof schema>) => Promise<T>,
): Promise<T> {
  const client = new Client({ connectionString: env.HYPERDRIVE.connectionString });
  await client.connect();
  try {
    return await operation(drizzle(client, { schema }));
  } finally {
    await client.end();
  }
}
