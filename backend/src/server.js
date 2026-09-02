import { createApp } from './app.js';
import { env } from './config/env.js';
import { createSeedData } from './data/seed-data.js';
import { JsonStore } from './data/store.js';

const store = await new JsonStore(env.dataFile).init(
  createSeedData(),
);

const app = createApp({
  store,
  jwtSecret: env.jwtSecret,
  allowedOrigin: env.allowedOrigin,
});

app.listen(env.port, () => {
  console.log(
    `Flutter Shop API running at http://localhost:${env.port}`,
  );
});