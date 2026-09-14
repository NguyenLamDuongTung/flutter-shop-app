export function errorHandler(
  error,
  request,
  response,
  next,
) {
  console.error(error);

  if (response.headersSent) {
    return next(error);
  }

  return response.status(500).json({
    message: 'Internal server error.',
  });
}