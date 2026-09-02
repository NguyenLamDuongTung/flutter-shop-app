import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { z } from 'zod';

import {
  verifyPassword,
} from '../security/password.js';

const loginSchema = z.object({
  email: z
    .string()
    .trim()
    .email(),

  password: z
    .string()
    .min(8)
    .max(128),
});

export function createAuthRouter({
  store,
  jwtSecret,
}) {
  const router = Router();

  router.post('/login', (request, response) => {
    const parsed = loginSchema.safeParse(
      request.body,
    );

    if (!parsed.success) {
      return response.status(400).json({
        message:
          'Enter a valid email and password.',
      });
    }

    const data = store.snapshot();

    const user = data.users.find(
      (candidate) =>
        candidate.email.toLowerCase() ===
        parsed.data.email.toLowerCase(),
    );

    if (
      !user ||
      !verifyPassword(
        parsed.data.password,
        user.passwordHash,
      )
    ) {
      return response.status(401).json({
        message:
          'Email or password is incorrect.',
      });
    }

    const publicUser = {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
    };

    const token = jwt.sign(
      publicUser,
      jwtSecret,
      {
        expiresIn: '2h',
      },
    );

    return response.json({
      token,
      user: publicUser,
    });
  });

  return router;
}