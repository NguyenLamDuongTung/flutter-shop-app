import { readFile } from 'node:fs/promises';

import { env } from '../config/env.js';
import { createDatabase } from './db.js';

const database = createDatabase(
  env.database,
);

try {
  const schema = await readFile(
    new URL(
      './schema.sql',
      import.meta.url,
    ),
    'utf8',
  );

  const statements = schema
    .split(';')
    .map((statement) => statement.trim())
    .filter((statement) => {
      return statement.length > 0;
    });

  for (const statement of statements) {
    await database.raw(statement);
  }

  console.log(
    'Database migration completed.',
  );
} catch (error) {
  console.error(
    'Database migration failed.',
  );

  console.error(error);

  process.exitCode = 1;
} finally {
  await database.close();
}