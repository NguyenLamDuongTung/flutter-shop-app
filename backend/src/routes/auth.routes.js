import express from 'express';
import jwt from 'jsonwebtoken';
import { z } from 'zod';

import { env } from '../config/env.js';
import { createDatabase } from '../database/db.js';
import {
  hashPassword,
  verifyPassword,
} from '../security/password.js';

const router = express.Router();

const database = createDatabase(
  env.database,
);

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  displayName: z.string().min(2).max(100),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

function createToken(user) {
  return jwt.sign(
    {
      sub: String(user.id),
      email: user.email,
      role: user.role,
    },
    env.jwtSecret,
    {
      expiresIn: '7d',
    },
  );
}

function publicUser(user) {
  return {
    id: Number(user.id),
    email: user.email,
    displayName: user.display_name,
    role: user.role,
  };
}

router.post('/register', async (request, response, next) => {
  try {
    const data =
      registerSchema.parse(request.body);

    const email =
      data.email.trim().toLowerCase();

    const existingUsers =
      await database.query(
        `
          SELECT id
          FROM users
          WHERE email = ?
          LIMIT 1
        `,
        [email],
      );

    if (existingUsers.length > 0) {
      return response.status(409).json({
        message: 'Email already exists.',
      });
    }

    const passwordHash =
      hashPassword(data.password);

    const result =
      await database.query(
        `
          INSERT INTO users (
            email,
            display_name,
            password_hash,
            role
          )
          VALUES (?, ?, ?, 'customer')
        `,
        [
          email,
          data.displayName.trim(),
          passwordHash,
        ],
      );

    const users =
      await database.query(
        `
          SELECT
            id,
            email,
            display_name,
            role
          FROM users
          WHERE id = ?
          LIMIT 1
        `,
        [result.insertId],
      );

    const user = users[0];

    return response.status(201).json({
      user: publicUser(user),
      token: createToken(user),
    });
  } catch (error) {
    next(error);
  }
});

router.post('/login', async (request, response, next) => {
  try {
    const data =
      loginSchema.parse(request.body);

    const email =
      data.email.trim().toLowerCase();

    const users =
      await database.query(
        `
          SELECT
            id,
            email,
            display_name,
            password_hash,
            role
          FROM users
          WHERE email = ?
          LIMIT 1
        `,
        [email],
      );

    if (users.length === 0) {
      return response.status(401).json({
        message: 'Invalid email or password.',
      });
    }

    const user = users[0];

    const valid =
      verifyPassword(
        data.password,
        user.password_hash,
      );

    if (!valid) {
      return response.status(401).json({
        message: 'Invalid email or password.',
      });
    }

    return response.json({
      user: publicUser(user),
      token: createToken(user),
    });
  } catch (error) {
    next(error);
  }
});

export default router;