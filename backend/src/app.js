import cors from 'cors';
import express from 'express';

import { requireAuth } from './middleware/auth.js';
import {
  errorHandler,
  notFound,
} from './middleware/error-handler.js';
import { createAuthRouter } from './routes/auth.routes.js';
import { createOrderRouter } from './routes/order.routes.js';
import { createProductRouter } from './routes/product.routes.js';

export function createApp({
  store,
  jwtSecret,
  allowedOrigin = '*',
}) {
  const app = express();

  app.disable('x-powered-by');

  app.use(
    cors({
      origin: allowedOrigin,
    }),
  );

  app.use(
    express.json({
      limit: '32kb',
    }),
  );

  app.get('/health', (request, response) => {
    return response.json({
      status: 'ok',
    });
  });

  app.use(
    '/api/auth',
    createAuthRouter({
      store,
      jwtSecret,
    }),
  );

  app.use(
    '/api/products',
    createProductRouter({
      store,
    }),
  );

  app.use(
    '/api/orders',
    requireAuth(jwtSecret),
    createOrderRouter({
      store,
    }),
  );

  app.use(notFound);
  app.use(errorHandler);

  return app;
}