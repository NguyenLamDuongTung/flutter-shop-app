import { rm } from 'node:fs/promises';

import { env } from './config/env.js';
import { createSeedData } from './data/seed-data.js';
import { JsonStore } from './data/store.js';

await rm(env.dataFile, {
  force: true,
});

await new JsonStore(env.dataFile).init(
  createSeedData(),
);

console.log('Database reset with deterministic demo data.');