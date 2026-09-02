import 'dotenv/config';

const port = Number.parseInt(
  process.env.PORT ?? '8080',
  10,
);

if (
  !Number.isInteger(port) ||
  port < 1 ||
  port > 65535
) {
  throw new Error(
    'PORT must be a valid number between 1 and 65535.',
  );
}

export const env = Object.freeze({
  port,

  jwtSecret:
    process.env.JWT_SECRET ??
    'local-development-secret-change-me',

  dataFile:
    process.env.DATA_FILE ??
    new URL('../../data/database.json', import.meta.url),

  allowedOrigin:
    process.env.ALLOWED_ORIGIN ?? '*',
});