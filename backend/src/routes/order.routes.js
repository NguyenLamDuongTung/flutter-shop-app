import { Router } from 'express';
import { z } from 'zod';

const orderSchema = z.object({
  customerName: z
    .string()
    .trim()
    .min(2)
    .max(80),

  address: z
    .string()
    .trim()
    .min(8)
    .max(200),

  items: z
    .array(
      z.object({
        productId: z
          .number()
          .int()
          .positive(),

        quantity: z
          .number()
          .int()
          .min(1)
          .max(20),
      }),
    )
    .min(1),
});

export function createOrderRouter({
  store,
}) {
  const router = Router();

  router.get('/', (request, response) => {
    const orders =
      store.snapshot().orders.filter(
        (order) =>
          order.userId === request.user.id,
      );

    return response.json({
      orders,
    });
  });

  router.post('/', async (request, response) => {
    const parsed = orderSchema.safeParse(
      request.body,
    );

    if (!parsed.success) {
      return response.status(400).json({
        message:
          'Check the checkout information and cart items.',
      });
    }

    const result = await store.update(
      (data) => {
        const requestedProducts = new Map();

        for (const item of parsed.data.items) {
          const previousQuantity =
            requestedProducts.get(
              item.productId,
            ) ?? 0;

          requestedProducts.set(
            item.productId,
            previousQuantity +
              item.quantity,
          );
        }

        const resolvedItems = [];

        for (
          const [productId, quantity]
          of requestedProducts
        ) {
          const product =
            data.products.find(
              (candidate) =>
                candidate.id ===
                productId,
            );

          if (!product) {
            return {
              error:
                'One of the products no longer exists.',
              status: 400,
            };
          }

          if (product.stock < quantity) {
            return {
              error:
                `${product.name} does not have enough stock.`,
              status: 409,
            };
          }

          resolvedItems.push({
            product,
            quantity,
          });
        }

        for (const item of resolvedItems) {
          item.product.stock -=
            item.quantity;
        }

        const orderItems =
          resolvedItems.map(
            ({
              product,
              quantity,
            }) => ({
              productId: product.id,
              name: product.name,
              unitPrice: product.price,
              quantity,
            }),
          );

        const total = Number(
          orderItems
            .reduce(
              (sum, item) =>
                sum +
                item.unitPrice *
                  item.quantity,
              0,
            )
            .toFixed(2),
        );

        const order = {
          id: data.nextOrderId,
          userId: request.user.id,
          customerName:
            parsed.data.customerName,
          address: parsed.data.address,
          status: 'confirmed',
          items: orderItems,
          total,
          createdAt:
            new Date().toISOString(),
        };

        data.nextOrderId += 1;
        data.orders.push(order);

        return {
          order,
        };
      },
    );

    if (result.error) {
      return response
        .status(result.status)
        .json({
          message: result.error,
        });
    }

    return response.status(201).json(
      result,
    );
  });

  return router;
}