import { Router } from 'express';

export function createProductRouter({
  store,
}) {
  const router = Router();

  router.get('/', (request, response) => {
    const search = String(
      request.query.search ?? '',
    )
      .trim()
      .toLowerCase();

    const category = String(
      request.query.category ?? '',
    )
      .trim()
      .toLowerCase();

    const products =
      store.snapshot().products.filter(
        (product) => {
          const searchableText =
            `${product.name} ${product.description}`
              .toLowerCase();

          const matchesSearch =
            search.length === 0 ||
            searchableText.includes(search);

          const matchesCategory =
            category.length === 0 ||
            product.category.toLowerCase() ===
              category;

          return (
            matchesSearch &&
            matchesCategory
          );
        },
      );

    return response.json({
      products,
    });
  });

  router.get('/:id', (request, response) => {
    const productId = Number(
      request.params.id,
    );

    const product =
      store.snapshot().products.find(
        (candidate) =>
          candidate.id === productId,
      );

    if (!product) {
      return response.status(404).json({
        message: 'Product was not found.',
      });
    }

    return response.json({
      product,
    });
  });

  return router;
}