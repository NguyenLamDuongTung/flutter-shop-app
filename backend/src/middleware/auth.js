import jwt from 'jsonwebtoken';

export function requireAuth(jwtSecret) {
  return (request, response, next) => {
    const authorization =
      request.get('authorization') ?? '';

    const [scheme, token] =
      authorization.split(' ');

    if (scheme !== 'Bearer' || !token) {
      return response.status(401).json({
        message: 'Authentication is required.',
      });
    }

    try {
      request.user = jwt.verify(
        token,
        jwtSecret,
      );

      return next();
    } catch {
      return response.status(401).json({
        message:
          'Your session is invalid or expired.',
      });
    }
  };
}