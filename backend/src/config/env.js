import 'dotenv/config';

function readPort(value, fallback) {
  const port = Number.parseInt(
    value ?? fallback,
    10,
  );

  if (
    !Number.isInteger(port) ||
    port < 1 ||
    port > 65535
  ) {
    throw new Error(
      `Invalid port value: ${value}`,
    );
  }

  return port;
}

export const env = Object.freeze({
  port: readPort(
    process.env.PORT,
    '8080',
  ),

  database: {
    host:
      process.env.DB_HOST ??
      '127.0.0.1',

    port: readPort(
      process.env.DB_PORT,
      '3306',
    ),

    name:
      process.env.DB_NAME ??
      'flutter_shop',

    user:
      process.env.DB_USER ??
      'flutter_shop_user',

    password:
      process.env.DB_PASSWORD ?? '',
  },

  jwtSecret:
    process.env.JWT_SECRET ??
    'local-development-secret-change-me',

  allowedOrigin:
    process.env.ALLOWED_ORIGIN ?? '*',
});