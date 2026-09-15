import cors from 'cors';
import express from 'express';

import { env } from './config/env.js';
import { errorHandler } from './middleware/error-handler.js';
import {
  authenticate,
  requireAdmin,
} from './middleware/auth.js';

import adminRoutes from './routes/admin.routes.js';
import authRoutes from './routes/auth.routes.js';
import productRoutes from './routes/product.routes.js';

const app = express();

app.use(
  cors({
    origin:
      env.allowedOrigin === '*'
        ? true
        : env.allowedOrigin,
  }),
);

app.use(express.json());

app.get('/api/health', (request, response) => {
  response.json({
    status: 'ok',
    service: 'flutter-shop-backend',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);

/*
 * Every route below /api/admin requires:
 * 1. A valid JWT.
 * 2. An account with role = admin.
 */
app.use(
  '/api/admin',
  authenticate,
  requireAdmin,
  adminRoutes,
);

app.use((request, response) => {
  response.status(404).json({
    message: 'Route not found.',
  });
});

app.use(errorHandler);

export default app;