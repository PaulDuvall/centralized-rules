# Express Best Practices

> **When to apply:** All Node.js applications using Express framework
> **Language:** TypeScript/JavaScript

Best practices for building production-ready Express applications with middleware, routing, error handling, security, and TypeScript integration.

## Project Structure

```
myapp/
├── src/
│   ├── index.ts              # App entry point
│   ├── app.ts                # Express app configuration
│   ├── config/               # Configuration
│   │   ├── database.ts
│   │   └── env.ts
│   ├── routes/               # Route handlers
│   │   ├── index.ts
│   │   ├── users.ts
│   │   └── posts.ts
│   ├── controllers/          # Request handlers
│   │   ├── userController.ts
│   │   └── postController.ts
│   ├── services/             # Business logic
│   │   ├── userService.ts
│   │   └── authService.ts
│   ├── models/               # Data models
│   │   ├── User.ts
│   │   └── Post.ts
│   ├── middleware/           # Custom middleware
│   │   ├── auth.ts
│   │   ├── errorHandler.ts
│   │   └── validation.ts
│   └── utils/                # Utilities
├── tests/
└── package.json
```

## Middleware Best Practices

### Ordering Matters

```typescript
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import morgan from 'morgan';

const app = express();

// 1. Security middleware (first)
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(','),
  credentials: true,
}));

// 2. Request parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 3. Logging
app.use(morgan('combined'));

// 4. Compression
app.use(compression());

// 5. Routes
app.use('/api/users', userRoutes);
app.use('/api/posts', postRoutes);

// 6. Error handling (last)
app.use(errorHandler);
```

### Custom Middleware

```typescript
// middleware/auth.ts
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
  userId?: string;
}

export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as { userId: string };
    req.userId = decoded.userId;
    
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};
```

## Routing

### Router-Based Organization

```typescript
// routes/users.ts
import { Router } from 'express';
import * as userController from '../controllers/userController';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { createUserSchema } from '../schemas/user';

const router = Router();

// Public routes
router.post('/register', validate(createUserSchema), userController.register);
router.post('/login', userController.login);

// Protected routes
router.get('/profile', authenticate, userController.getProfile);
router.put('/profile', authenticate, validate(updateUserSchema), userController.updateProfile);
router.delete('/account', authenticate, userController.deleteAccount);

export default router;
```

### Controller Pattern

```typescript
// controllers/userController.ts
import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import * as userService from '../services/userService';

export const register = async (req: Request, res: Response) => {
  try {
    const user = await userService.createUser(req.body);
    res.status(201).json({ user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

export const getProfile = async (req: AuthRequest, res: Response) => {
  try {
    const user = await userService.getUserById(req.userId!);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ user });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};
```

## Error Handling

### Centralized Error Handler

```typescript
// middleware/errorHandler.ts
import { Request, Response, NextFunction } from 'express';

export class AppError extends Error {
  statusCode: number;
  
  constructor(message: string, statusCode: number = 500) {
    super(message);
    this.statusCode = statusCode;
    Error.captureStackTrace(this, this.constructor);
  }
}

export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.error(err);

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: err.message,
    });
  }

  // Validation errors
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      error: 'Validation failed',
      details: err.message,
    });
  }

  // Default error
  res.status(500).json({
    error: process.env.NODE_ENV === 'production' 
      ? 'Internal server error' 
      : err.message,
  });
};

// Async error wrapper
export const asyncHandler = (fn: Function) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
```

## Request Validation

### Using Zod

```typescript
// schemas/user.ts
import { z } from 'zod';

export const createUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(2).max(100),
});

export const updateUserSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  bio: z.string().max(500).optional(),
});

// middleware/validation.ts
import { Request, Response, NextFunction } from 'express';
import { ZodSchema } from 'zod';

export const validate = (schema: ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse(req.body);
      next();
    } catch (error) {
      res.status(400).json({
        error: 'Validation failed',
        details: error.errors,
      });
    }
  };
};
```

## Security Best Practices

### Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests, please try again later',
});

app.use('/api/', limiter);

// Stricter limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts',
});

app.use('/api/auth/login', authLimiter);
```

### Input Sanitization

```typescript
import mongoSanitize from 'express-mongo-sanitize';
import xss from 'xss-clean';

// Prevent NoSQL injection
app.use(mongoSanitize());

// Prevent XSS attacks
app.use(xss());
```

## Testing

### Integration Tests

```typescript
import request from 'supertest';
import app from '../app';

describe('User API', () => {
  it('should register a new user', async () => {
    const response = await request(app)
      .post('/api/users/register')
      .send({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      })
      .expect(201);

    expect(response.body.user).toHaveProperty('id');
    expect(response.body.user.email).toBe('test@example.com');
  });

  it('should require authentication for profile', async () => {
    await request(app)
      .get('/api/users/profile')
      .expect(401);
  });
});
```

## Performance

### Database Connection Pooling

```typescript
// config/database.ts
import { Pool } from 'pg';

export const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20, // Maximum pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

### Response Caching

```typescript
import mcache from 'memory-cache';

const cache = (duration: number) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const key = '__express__' + req.originalUrl;
    const cached = mcache.get(key);

    if (cached) {
      return res.send(cached);
    }

    const originalSend = res.send;
    res.send = function (body) {
      mcache.put(key, body, duration * 1000);
      return originalSend.call(this, body);
    };

    next();
  };
};

// Cache for 5 minutes
app.get('/api/posts', cache(300), postController.list);
```

## Related Resources

- See `languages/typescript/coding-standards.md` for TypeScript patterns
- See `languages/typescript/testing.md` for testing strategies
- See `base/security-principles.md` for security guidelines
