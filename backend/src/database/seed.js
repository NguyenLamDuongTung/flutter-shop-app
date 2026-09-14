import { env } from '../config/env.js';
import { hashPassword } from '../security/password.js';
import { createDatabase } from './db.js';

const database = createDatabase(
  env.database,
);

const products = [
  {
    name: 'iPhone 16 Pro',
    description:
      'Điện thoại cao cấp, hiệu năng mạnh và camera chuyên nghiệp.',
    category: 'Điện thoại',
    price: 28990000,
    stock: 12,
    imageUrl:
      'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=1000',
  },
  {
    name: 'MacBook Air M3',
    description:
      'Laptop mỏng nhẹ cho học tập, công việc và sáng tạo.',
    category: 'Laptop',
    price: 26990000,
    stock: 8,
    imageUrl:
      'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1000',
  },
  {
    name: 'Apple Watch Series 10',
    description:
      'Theo dõi sức khỏe và luyện tập hằng ngày.',
    category: 'Đồng hồ',
    price: 10990000,
    stock: 15,
    imageUrl:
      'https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?w=1000',
  },
  {
    name: 'AirPods Pro',
    description:
      'Tai nghe chống ồn chủ động, âm thanh sống động.',
    category: 'Âm thanh',
    price: 5990000,
    stock: 20,
    imageUrl:
      'https://images.unsplash.com/photo-1606220945770-b5b6c2c55bf1?w=1000',
  },
  {
    name: 'Galaxy S25 Ultra',
    description:
      'Màn hình sắc nét, bút S Pen và camera zoom xa.',
    category: 'Điện thoại',
    price: 30990000,
    stock: 10,
    imageUrl:
      'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=1000',
  },
  {
    name: 'Dell XPS 13',
    description:
      'Laptop Windows cao cấp với thiết kế nhỏ gọn.',
    category: 'Laptop',
    price: 31990000,
    stock: 6,
    imageUrl:
      'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=1000',
  },
];

async function createUser({
  email,
  displayName,
  password,
  role,
}) {
  const existingUsers =
    await database.query(
      `
        SELECT id
        FROM users
        WHERE LOWER(email) = LOWER(?)
        LIMIT 1
      `,
      [email],
    );

  if (existingUsers.length > 0) {
    return;
  }

  await database.query(
    `
      INSERT INTO users (
        email,
        display_name,
        password_hash,
        role
      )
      VALUES (?, ?, ?, ?)
    `,
    [
      email.toLowerCase(),
      displayName,
      hashPassword(password),
      role,
    ],
  );
}

async function createProduct(product) {
  const existingProducts =
    await database.query(
      `
        SELECT id
        FROM products
        WHERE name = ?
        LIMIT 1
      `,
      [product.name],
    );

  if (existingProducts.length > 0) {
    return;
  }

  await database.query(
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
      VALUES (?, ?, ?, ?, ?, ?, TRUE)
    `,
    [
      product.name,
      product.description,
      product.category,
      product.price,
      product.stock,
      product.imageUrl,
    ],
  );
}

try {
  await createUser({
    email: 'customer@shop.test',
    displayName: 'Demo Customer',
    password: 'Test123!',
    role: 'customer',
  });

  await createUser({
    email: 'admin@shop.test',
    displayName: 'Store Administrator',
    password: 'Admin123!',
    role: 'admin',
  });

  for (const product of products) {
    await createProduct(product);
  }

  console.log('Seed data created.');
} catch (error) {
  console.error(
    'Could not create seed data.',
  );

  console.error(error);

  process.exitCode = 1;
} finally {
  await database.close();
}