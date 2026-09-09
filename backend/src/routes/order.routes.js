import { Router } from 'express';
import { z } from 'zod';

const orderSchema = z.object({
  customerName: z
    .string()
    .trim()
    .min(2)
    .max(80),

  phone: z
    .string()
    .trim()
    .regex(
      /^(0|\+84)[0-9]{9,10}$/,
      'Phone number is invalid.',
    ),

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

export function createOrderRouter({ store }) {
  const router = Router();

  router.get('/', (request, response) => {
    const orders = store
      .snapshot()
      .orders
      .filter(
        (order) =>
          order.userId === request.user.id,
      )
      .sort((first, second) => {
        return new Date(second.createdAt) -
          new Date(first.createdAt);
      });

    return response.json({
      orders,
    });
  });

  router.post('/', async (request, response) => {
    const parsed =
      orderSchema.safeParse(request.body);

    if (!parsed.success) {
      return response.status(400).json({
        message:
          'Vui lòng kiểm tra thông tin nhận hàng.',
        errors: parsed.error.flatten(),
      });
    }

    const result = await store.update((data) => {
      const requestedProducts = new Map();

      for (const item of parsed.data.items) {
        const previousQuantity =
          requestedProducts.get(
            item.productId,
          ) ?? 0;

        requestedProducts.set(
          item.productId,
          previousQuantity + item.quantity,
        );
      }

      const resolvedItems = [];

      for (
        const [productId, quantity]
        of requestedProducts
      ) {
        const product = data.products.find(
          (candidate) =>
            candidate.id === productId,
        );

        if (!product) {
          return {
            error:
              'Một sản phẩm không còn tồn tại.',
            status: 400,
          };
        }

        if (product.stock < quantity) {
          return {
            error:
              `${product.name} không đủ số lượng trong kho.`,
            status: 409,
          };
        }

        resolvedItems.push({
          product,
          quantity,
        });
      }

      for (const item of resolvedItems) {
        item.product.stock -= item.quantity;
      }

      const orderItems = resolvedItems.map(
        ({ product, quantity }) => {
          return {
            productId: product.id,
            name: product.name,
            imageUrl: product.imageUrl,
            unitPrice: product.price,
            quantity,
            subtotal: Number(
              (
                product.price * quantity
              ).toFixed(2),
            ),
          };
        },
      );

      const total = Number(
        orderItems
          .reduce(
            (sum, item) =>
              sum + item.subtotal,
            0,
          )
          .toFixed(2),
      );

      const order = {
        id: data.nextOrderId,
        userId: request.user.id,
        customerName:
          parsed.data.customerName,
        phone: parsed.data.phone,
        address: parsed.data.address,
        status: 'confirmed',
        items: orderItems,
        total,
        createdAt: new Date().toISOString(),
      };

      data.nextOrderId += 1;
      data.orders.push(order);

      return {
        order,
      };
    });

    if (result.error) {
      return response
        .status(result.status)
        .json({
          message: result.error,
        });
    }

    return response.status(201).json(result);
  });

  return router;
}