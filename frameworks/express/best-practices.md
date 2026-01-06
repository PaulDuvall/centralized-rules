# Express Best Practices

> **When to apply:** All Node.js applications using Express framework
> **Framework:** Express 4.18+
> **Language:** TypeScript/JavaScript

Production-ready Express development with middleware, routing, error handling, security, and TypeScript integration.

## Project Structure

```
myapp/
├── src/
│   ├── index.ts              # App entry point
│   ├── app.ts                # Express app configuration
│   ├── config/               # Configuration
│   ├── routes/               # Route handlers
│   ├── controllers/          # Request handlers
│   ├── services/             # Business logic
│   ├── models/               # Data models
│   ├── middleware/           # Custom middleware
│   └── utils/
├── tests/
└── package.json
```

## Middleware Configuration

**Rule:** Apply middleware in correct order: security → parsing → logging → compression → routes → error handling.

```typescript
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import morgan from 'morgan';

const app = express();

// 1. Security (first)
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(','),
  credentials: true,
}));

// 2. Parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 3. Logging
app.use(morgan('combined'));

// 4. Compression
app.use(compression());

// 5. Routes
app.use('/api/users', userRoutes);

// 6. Error handling (last)
app.use(errorHandler);
```

## Custom Middleware

**Rule:** Define typed middleware with proper error handling. Use `NextFunction` for middleware chaining.

```typescript
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

**Rule:** Organize routes by resource. Use Router for modular route definitions. Apply validation middleware.

```typescript
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

## Controller Pattern

**Rule:** Controllers handle HTTP. Delegate business logic to services. Return consistent response structure.

```typescript
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

**Rule:** Use centralized error handler. Create custom error classes. Never expose stack traces in production.

```typescript
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
    return res.status(err.statusCode).json({ error: err.message });
  }

  if (err.name === 'ValidationError') {
    return res.status(400).json({ error: 'Validation failed', details: err.message });
  }

  res.status(500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message
  });
};

// Async wrapper
export const asyncHandler = (fn: Function) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
```

## Request Validation

**Rule:** Validate all input with Zod schemas. Apply validation middleware before controllers.

```typescript
import { z } from 'zod';
import { Request, Response, NextFunction } from 'express';

// Schema definition
export const createUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(2).max(100),
});

export const updateUserSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  bio: z.string().max(500).optional(),
});

// Validation middleware
export const validate = (schema: z.ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse(req.body);
      next();
    } catch (error) {
      res.status(400).json({ error: 'Validation failed', details: error.errors });
    }
  };
};
```

## Security

**Rule:** Apply rate limiting. Sanitize input. Use helmet for security headers.

```typescript
import rateLimit from 'express-rate-limit';
import mongoSanitize from 'express-mongo-sanitize';
import xss from 'xss-clean';

// Global rate limiter
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many requests',
});
app.use('/api/', limiter);

// Strict limiter for auth
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts',
});
app.use('/api/auth/login', authLimiter);

// Input sanitization
app.use(mongoSanitize());  // Prevent NoSQL injection
app.use(xss());             // Prevent XSS attacks
```

## Testing

**Rule:** Use supertest for integration tests. Test all routes and error cases.

```typescript
import request from 'supertest';
import app from '../app';

describe('User API', () => {
  it('should register new user', async () => {
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

## Database Connection

**Rule:** Use connection pooling. Handle connection errors gracefully.

```typescript
import { Pool } from 'pg';

export const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

## Response Caching

**Rule:** Cache static or infrequently changing data. Use cache headers.

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

- `languages/typescript/coding-standards.md` - TypeScript patterns
- `languages/typescript/testing.md` - Testing strategies
- `base/security-principles.md` - Security guidelines
