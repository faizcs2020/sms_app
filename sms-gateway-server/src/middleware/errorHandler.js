const errorHandler = (err, req, res, next) => {
  console.error(`[Error] ${err.name || 'ServerError'}: ${err.message}`);
  if (err.stack && process.env.NODE_ENV !== 'production') {
    console.error(err.stack);
  }

  let statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  let message = err.message || 'Internal Server Error';
  let errorCode = err.errorCode || 'INTERNAL_SERVER_ERROR';

  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = Object.values(err.errors).map(val => val.message).join(', ');
    errorCode = 'VALIDATION_ERROR';
  } else if (err.code === 11000) {
    statusCode = 400;
    message = 'Duplicate key error: Record already exists';
    errorCode = 'DUPLICATE_KEY_ERROR';
  } else if (err.name === 'CastError') {
    statusCode = 400;
    message = `Invalid format for field: ${err.path}`;
    errorCode = 'INVALID_FORMAT';
  }

  res.status(statusCode).json({
    success: false,
    message,
    errorCode,
  });
};

module.exports = errorHandler;
