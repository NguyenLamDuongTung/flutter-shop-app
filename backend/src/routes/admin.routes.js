import express from 'express';
import { z } from 'zod';

import { env } from '../config/env.js';
import { createDatabase } from '../database/db.js';

const router = express.Router();
const database = createDatabase(env.database);

const productSchema = z.object({
  name: z.string().trim().min(2).max(160),
  description: z.string().trim().min(2),
  category: z.string().trim().min(2).max(80),
  price: z.coerce.number().min(0),
  stock: z.coerce.number().int().min(0),
  imageUrl: z.string().trim().url(),
  isActive: z.boolean().default(true),
});

const orderStatusSchema = z.object({
  status: z.enum([
    'pending',
    'confirmed',
    'shipping',
    'completed',
    'cancelled',
  ]),
});

function parseId(value) {
  const id = Number(value);
  return Number.isSafeInteger(id) && id > 0 ? id : null;
}

function mapProduct(product) {
  return {
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
  };
}

/*
 * GET /api/admin/dashboard
 * Dashboard totals, recent orders and monthly revenue.
 */
router.get('/dashboard', async (request, response, next) => {
  try {
    const [summary] = await database.query(`
      SELECT
        (
          SELECT COUNT(*)
          FROM users
          WHERE role = 'customer'
        ) AS total_customers,

        (
          SELECT COUNT(*)
          FROM products
        ) AS total_products,

        (
          SELECT COUNT(*)
          FROM products
          WHERE is_active = TRUE
        ) AS active_products,

        (
          SELECT COUNT(*)
          FROM products
          WHERE stock <= 5
            AND is_active = TRUE
        ) AS low_stock_products,

        (
          SELECT COUNT(*)
          FROM orders
        ) AS total_orders,

        (
          SELECT COUNT(*)
          FROM orders
          WHERE status = 'pending'
        ) AS pending_orders,

        (
          SELECT COALESCE(SUM(total), 0)
          FROM orders
          WHERE status = 'completed'
        ) AS total_revenue,

        (
          SELECT COALESCE(SUM(total), 0)
          FROM orders
          WHERE status = 'completed'
            AND YEAR(created_at) = YEAR(CURRENT_DATE())
            AND MONTH(created_at) = MONTH(CURRENT_DATE())
        ) AS monthly_revenue
    `);

    const monthlyRevenue = await database.query(`
      SELECT
        DATE_FORMAT(created_at, '%Y-%m') AS month,
        COUNT(*) AS order_count,
        COALESCE(SUM(total), 0) AS revenue
      FROM orders
      WHERE status = 'completed'
        AND created_at >= DATE_SUB(
          DATE_FORMAT(CURRENT_DATE(), '%Y-%m-01'),
          INTERVAL 11 MONTH
        )
      GROUP BY DATE_FORMAT(created_at, '%Y-%m')
      ORDER BY month ASC
    `);

    const recentOrders = await database.query(`
      SELECT
        o.id,
        o.customer_name,
        u.email AS customer_email,
        o.phone,
        o.status,
        o.total,
        o.created_at
      FROM orders o
      INNER JOIN users u ON u.id = o.user_id
      ORDER BY o.created_at DESC, o.id DESC
      LIMIT 10
    `);

    const bestSellingProducts = await database.query(`
      SELECT
        oi.product_id,
        oi.product_name,
        SUM(oi.quantity) AS quantity_sold,
        SUM(oi.subtotal) AS revenue
      FROM order_items oi
      INNER JOIN orders o ON o.id = oi.order_id
      WHERE o.status <> 'cancelled'
      GROUP BY oi.product_id, oi.product_name
      ORDER BY quantity_sold DESC, revenue DESC
      LIMIT 5
    `);

    return response.json({
      summary: {
        totalCustomers: Number(summary.total_customers),
        totalProducts: Number(summary.total_products),
        activeProducts: Number(summary.active_products),
        lowStockProducts: Number(summary.low_stock_products),
        totalOrders: Number(summary.total_orders),
        pendingOrders: Number(summary.pending_orders),
        totalRevenue: Number(summary.total_revenue),
        monthlyRevenue: Number(summary.monthly_revenue),
      },

      monthlyRevenue: monthlyRevenue.map((item) => ({
        month: item.month,
        orderCount: Number(item.order_count),
        revenue: Number(item.revenue),
      })),

      recentOrders: recentOrders.map((order) => ({
        id: Number(order.id),
        customerName: order.customer_name,
        customerEmail: order.customer_email,
        phone: order.phone,
        status: order.status,
        total: Number(order.total),
        createdAt: order.created_at,
      })),

      bestSellingProducts: bestSellingProducts.map((item) => ({
        productId:
          item.product_id === null
            ? null
            : Number(item.product_id),
        productName: item.product_name,
        quantitySold: Number(item.quantity_sold),
        revenue: Number(item.revenue),
      })),
    });
  } catch (error) {
    next(error);
  }
});

/*
 * GET /api/admin/products
 */
router.get('/products', async (request, response, next) => {
  try {
    const products = await database.query(`
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
      ORDER BY created_at DESC, id DESC
    `);

    return response.json(products.map(mapProduct));
  } catch (error) {
    next(error);
  }
});

/*
 * POST /api/admin/products
 */
router.post('/products', async (request, response, next) => {
  try {
    const result = productSchema.safeParse(request.body);

    if (!result.success) {
      return response.status(400).json({
        message: 'Invalid product information.',
        errors: result.error.flatten().fieldErrors,
      });
    }

    const product = result.data;

    const insertResult = await database.query(
      `
        INSERT INTO products (
          name,
          description,
          category,
          price,
          stock,
          image_url,
          is_active
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `,
      [
        product.name,
        product.description,
        product.category,
        product.price,
        product.stock,
        product.imageUrl,
        product.isActive,
      ],
    );

    const products = await database.query(
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
      [insertResult.insertId],
    );

    return response.status(201).json(mapProduct(products[0]));
  } catch (error) {
    next(error);
  }
});

/*
 * PUT /api/admin/products/:id
 */
router.put('/products/:id', async (request, response, next) => {
  try {
    const id = parseId(request.params.id);

    if (id === null) {
      return response.status(400).json({
        message: 'Invalid product ID.',
      });
    }

    const result = productSchema.safeParse(request.body);

    if (!result.success) {
      return response.status(400).json({
        message: 'Invalid product information.',
        errors: result.error.flatten().fieldErrors,
      });
    }

    const existingProducts = await database.query(
      'SELECT id FROM products WHERE id = ? LIMIT 1',
      [id],
    );

    if (existingProducts.length === 0) {
      return response.status(404).json({
        message: 'Product not found.',
      });
    }

    const product = result.data;

    await database.query(
      `
        UPDATE products
        SET
          name = ?,
          description = ?,
          category = ?,
          price = ?,
          stock = ?,
          image_url = ?,
          is_active = ?
        WHERE id = ?
      `,
      [
        product.name,
        product.description,
        product.category,
        product.price,
        product.stock,
        product.imageUrl,
        product.isActive,
        id,
      ],
    );

    const products = await database.query(
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

    return response.json(mapProduct(products[0]));
  } catch (error) {
    next(error);
  }
});

/*
 * DELETE /api/admin/products/:id
 *
 * Uses soft delete to preserve old order history.
 */
router.delete('/products/:id', async (request, response, next) => {
  try {
    const id = parseId(request.params.id);

    if (id === null) {
      return response.status(400).json({
        message: 'Invalid product ID.',
      });
    }

    const updateResult = await database.query(
      `
        UPDATE products
        SET is_active = FALSE
        WHERE id = ?
      `,
      [id],
    );

    if (updateResult.affectedRows === 0) {
      return response.status(404).json({
        message: 'Product not found.',
      });
    }

    return response.json({
      message: 'Product hidden successfully.',
    });
  } catch (error) {
    next(error);
  }
});

/*
 * GET /api/admin/orders
 */
router.get('/orders', async (request, response, next) => {
  try {
    const status =
      typeof request.query.status === 'string'
        ? request.query.status
        : null;

    const allowedStatuses = [
      'pending',
      'confirmed',
      'shipping',
      'completed',
      'cancelled',
    ];

    if (status !== null && !allowedStatuses.includes(status)) {
      return response.status(400).json({
        message: 'Invalid order status.',
      });
    }

    const parameters = [];

    let whereClause = '';

    if (status !== null) {
      whereClause = 'WHERE o.status = ?';
      parameters.push(status);
    }

    const orders = await database.query(
      `
        SELECT
          o.id,
          o.user_id,
          u.email AS customer_email,
          o.customer_name,
          o.phone,
          o.address,
          o.status,
          o.total,
          o.created_at,
          o.updated_at
        FROM orders o
        INNER JOIN users u ON u.id = o.user_id
        ${whereClause}
        ORDER BY o.created_at DESC, o.id DESC
      `,
      parameters,
    );

    const output = [];

    for (const order of orders) {
      const items = await database.query(
        `
          SELECT
            id,
            product_id,
            product_name,
            image_url,
            unit_price,
            quantity,
            subtotal
          FROM order_items
          WHERE order_id = ?
          ORDER BY id ASC
        `,
        [order.id],
      );

      output.push({
        id: Number(order.id),
        userId: Number(order.user_id),
        customerEmail: order.customer_email,
        customerName: order.customer_name,
        phone: order.phone,
        address: order.address,
        status: order.status,
        total: Number(order.total),
        createdAt: order.created_at,
        updatedAt: order.updated_at,

        items: items.map((item) => ({
          id: Number(item.id),
          productId:
            item.product_id === null
              ? null
              : Number(item.product_id),
          productName: item.product_name,
          imageUrl: item.image_url,
          unitPrice: Number(item.unit_price),
          quantity: Number(item.quantity),
          subtotal: Number(item.subtotal),
        })),
      });
    }

    return response.json(output);
  } catch (error) {
    next(error);
  }
});

/*
 * PATCH /api/admin/orders/:id/status
 */
router.patch(
  '/orders/:id/status',
  async (request, response, next) => {
    try {
      const id = parseId(request.params.id);

      if (id === null) {
        return response.status(400).json({
          message: 'Invalid order ID.',
        });
      }

      const result = orderStatusSchema.safeParse(request.body);

      if (!result.success) {
        return response.status(400).json({
          message: 'Invalid order status.',
        });
      }

      const orders = await database.query(
        `
          SELECT id, status
          FROM orders
          WHERE id = ?
          LIMIT 1
        `,
        [id],
      );

      if (orders.length === 0) {
        return response.status(404).json({
          message: 'Order not found.',
        });
      }

      await database.query(
        `
          UPDATE orders
          SET status = ?
          WHERE id = ?
        `,
        [result.data.status, id],
      );

      return response.json({
        id,
        status: result.data.status,
        message: 'Order status updated.',
      });
    } catch (error) {
      next(error);
    }
  },
);

/*
 * GET /api/admin/customers
 */
router.get('/customers', async (request, response, next) => {
  try {
    const customers = await database.query(`
      SELECT
        u.id,
        u.email,
        u.display_name,
        u.created_at,
        COUNT(o.id) AS order_count,
        COALESCE(
          SUM(
            CASE
              WHEN o.status <> 'cancelled'
              THEN o.total
              ELSE 0
            END
          ),
          0
        ) AS total_spent,
        MAX(o.created_at) AS last_order_at
      FROM users u
      LEFT JOIN orders o ON o.user_id = u.id
      WHERE u.role = 'customer'
      GROUP BY
        u.id,
        u.email,
        u.display_name,
        u.created_at
      ORDER BY last_order_at DESC, u.created_at DESC
    `);

    return response.json(
      customers.map((customer) => ({
        id: Number(customer.id),
        email: customer.email,
        displayName: customer.display_name,
        createdAt: customer.created_at,
        orderCount: Number(customer.order_count),
        totalSpent: Number(customer.total_spent),
        lastOrderAt: customer.last_order_at,
      })),
    );
  } catch (error) {
    next(error);
  }
});

/*
 * GET /api/admin/customers/:id
 * Customer details and complete order history.
 */
router.get('/customers/:id', async (request, response, next) => {
  try {
    const id = parseId(request.params.id);

    if (id === null) {
      return response.status(400).json({
        message: 'Invalid customer ID.',
      });
    }

    const customers = await database.query(
      `
        SELECT
          id,
          email,
          display_name,
          role,
          created_at
        FROM users
        WHERE id = ?
          AND role = 'customer'
        LIMIT 1
      `,
      [id],
    );

    if (customers.length === 0) {
      return response.status(404).json({
        message: 'Customer not found.',
      });
    }

    const orders = await database.query(
      `
        SELECT
          id,
          customer_name,
          phone,
          address,
          status,
          total,
          created_at,
          updated_at
        FROM orders
        WHERE user_id = ?
        ORDER BY created_at DESC, id DESC
      `,
      [id],
    );

    const orderHistory = [];

    for (const order of orders) {
      const items = await database.query(
        `
          SELECT
            id,
            product_id,
            product_name,
            image_url,
            unit_price,
            quantity,
            subtotal
          FROM order_items
          WHERE order_id = ?
          ORDER BY id ASC
        `,
        [order.id],
      );

      orderHistory.push({
        id: Number(order.id),
        customerName: order.customer_name,
        phone: order.phone,
        address: order.address,
        status: order.status,
        total: Number(order.total),
        createdAt: order.created_at,
        updatedAt: order.updated_at,

        items: items.map((item) => ({
          id: Number(item.id),
          productId:
            item.product_id === null
              ? null
              : Number(item.product_id),
          productName: item.product_name,
          imageUrl: item.image_url,
          unitPrice: Number(item.unit_price),
          quantity: Number(item.quantity),
          subtotal: Number(item.subtotal),
        })),
      });
    }

    const customer = customers[0];

    return response.json({
      customer: {
        id: Number(customer.id),
        email: customer.email,
        displayName: customer.display_name,
        createdAt: customer.created_at,
      },
      orders: orderHistory,
    });
  } catch (error) {
    next(error);
  }
});

export default router;