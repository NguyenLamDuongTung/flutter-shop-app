import express from 'express';

import { env } from '../config/env.js';
import { createDatabase } from '../database/db.js';

const router = express.Router();

const database = createDatabase(
  env.database,
);

router.get('/', async (request, response, next) => {
  try {
    const products =
      await database.query(
        `
          SELECT
            id,
            name,
            description,
            category,
            price,
            stock,
            image_url,
            is_active,
            created_at,
            updated_at
          FROM products
          WHERE is_active = TRUE
          ORDER BY created_at DESC, id DESC
        `,
      );

    return response.json(
      products.map((product) => ({
        id: Number(product.id),
        name: product.name,
        description: product.description,
        category: product.category,
        price: Number(product.price),
        stock: Number(product.stock),
        imageUrl: product.image_url,
        isActive: Boolean(product.is_active),
        createdAt: product.created_at,
        updatedAt: product.updated_at,
      })),
    );
  } catch (error) {
    next(error);
  }
});

router.get('/:id', async (request, response, next) => {
  try {
    const id =
      Number(request.params.id);

    if (!Number.isInteger(id)) {
      return response.status(400).json({
        message: 'Invalid product ID.',
      });
    }

    const products =
      await database.query(
        `
          SELECT
            id,
            name,
            description,
            category,
            price,
            stock,
            image_url,
            is_active,
            created_at,
            updated_at
          FROM products
          WHERE id = ?
          LIMIT 1
        `,
        [id],
      );

    if (products.length === 0) {
      return response.status(404).json({
        message: 'Product not found.',
      });
    }

    const product = products[0];

    return response.json({
      id: Number(product.id),
      name: product.name,
      description: product.description,
      category: product.category,
      price: Number(product.price),
      stock: Number(product.stock),
      imageUrl: product.image_url,
      isActive: Boolean(product.is_active),
      createdAt: product.created_at,
      updatedAt: product.updated_at,
    });
  } catch (error) {
    next(error);
  }
});

export default router;