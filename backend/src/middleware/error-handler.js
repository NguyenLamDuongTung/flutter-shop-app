export function notFound(request, response) {
  return response.status(404).json({
    message:
      `Route ${request.method} ${request.path} was not found.`,
  });
}

export function errorHandler(
  error,
  request,
  response,
  next,
) {
  void request;
  void next;

  console.error(error);

  return response.status(500).json({
    message:
      'The server could not complete the request.',
  });
}