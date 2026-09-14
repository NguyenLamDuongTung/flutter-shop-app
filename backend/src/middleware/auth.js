import jwt from 'jsonwebtoken';

import { env } from '../config/env.js';

function extractToken(request) {
  const authorization =
    request.headers.authorization;

  if (
    typeof authorization !== 'string' ||
    !authorization.startsWith('Bearer ')
  ) {
    return null;
  }

  return authorization.substring(7).trim();
}

export function authenticate(request, response, next) {
  const token = extractToken(request);

  if (!token) {
    return response.status(401).json({
      message: 'Authentication required.',
    });
  }

  try {
    const payload = jwt.verify(
      token,
      env.jwtSecret,
    );

    request.user = {
      id: Number(payload.sub),
      email: payload.email,
      role: payload.role,
    };

    next();
  } catch {
    return response.status(401).json({
      message: 'Invalid or expired token.',
    });
  }
}

export function requireAdmin(
  request,
  response,
  next,
) {
  if (!request.user) {
    return response.status(401).json({
      message: 'Authentication required.',
    });
  }

  if (request.user.role !== 'admin') {
    return response.status(403).json({
      message: 'Admin access required.',
    });
  }

  next();
}