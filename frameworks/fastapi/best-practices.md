# FastAPI Best Practices

> **When to apply:** All Python applications using FastAPI framework
> **Framework:** FastAPI 0.100+
> **Language:** Python 3.11+

Production-ready FastAPI development with async endpoints, Pydantic validation, dependency injection, and testing.

## Project Structure

```
myapp/
├── app/
│   ├── main.py              # FastAPI app instance
│   ├── config.py            # Configuration
│   ├── dependencies.py      # Shared dependencies
│   ├── models/              # Pydantic models
│   ├── routers/             # API routes
│   ├── services/            # Business logic
│   ├── db/                  # Database (models, migrations)
│   └── utils/
├── tests/
├── alembic/                 # Database migrations
├── requirements.txt
└── .env.example
```

## Application Setup

**Main application:**
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

app = FastAPI(
    title=settings.APP_NAME,
    docs_url="/api/docs" if settings.DEBUG else None,
    redoc_url="/api/redoc" if settings.DEBUG else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router, prefix="/api/users", tags=["users"])
```

## Async Endpoints

**Rule:** Use `async def` for I/O-bound operations (database, HTTP, file I/O). Use `def` for CPU-bound operations.

```python
# ✅ Async for I/O operations
@router.get("/users/{user_id}")
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()

# ✅ Async HTTP requests
@router.get("/external")
async def fetch_external():
    async with httpx.AsyncClient() as client:
        response = await client.get("https://api.example.com/data")
        return response.json()

# ✅ Concurrent operations with asyncio.gather
@router.get("/dashboard")
async def dashboard(db: AsyncSession = Depends(get_db)):
    users, posts, stats = await asyncio.gather(
        db.execute(select(User).limit(10)),
        db.execute(select(Post).limit(10)),
        get_statistics()
    )
    return {"users": users.scalars().all(), "posts": posts.scalars().all(), "stats": stats}
```

## Pydantic Models

**Rule:** Define separate models for request, response, and internal use. Use validation for all input.

```python
from pydantic import BaseModel, EmailStr, Field, validator

# Base model
class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50, pattern="^[a-zA-Z0-9_-]+$")

# Request model
class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

    @validator('password')
    def validate_password(cls, v):
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain digit')
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain uppercase')
        return v

# Response model
class UserResponse(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True  # Allow ORM conversion

# Update model (partial)
class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = Field(None, min_length=3, max_length=50)
```

## Dependency Injection

**Rule:** Use dependencies for database sessions, authentication, pagination, and shared logic.

```python
# Database session
async def get_db() -> AsyncSession:
    async with async_session_maker() as session:
        try:
            yield session
        finally:
            await session.close()

# Authentication
async def get_current_user(
    token: Annotated[str, Header(alias="Authorization")],
    db: AsyncSession = Depends(get_db)
) -> User:
    token = token.replace("Bearer ", "")
    payload = decode_jwt(token)
    user_id = payload.get("user_id")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return user

# Reusable dependencies
class Pagination:
    def __init__(self, skip: int = 0, limit: int = 100, max_limit: int = 1000):
        if limit > max_limit:
            raise HTTPException(400, f"Limit cannot exceed {max_limit}")
        self.skip = skip
        self.limit = limit

# Usage
@router.get("/posts")
async def list_posts(
    pagination: Pagination = Depends(),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Post).offset(pagination.skip).limit(pagination.limit)
    result = await db.execute(query)
    return result.scalars().all()
```

## Request Validation

**Rule:** Validate all path, query, and body parameters with Field constraints.

```python
from fastapi import Path, Query

@router.get("/users/{user_id}")
async def get_user(
    user_id: int = Path(..., gt=0, description="User ID")
):
    pass

@router.get("/search")
async def search(
    q: str = Query(..., min_length=3, max_length=100),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100)
):
    pass
```

## Error Handling

**Rule:** Use custom exceptions and global handlers for consistent error responses.

```python
# Custom exceptions
class UserNotFoundError(HTTPException):
    def __init__(self, user_id: int):
        super().__init__(status_code=404, detail=f"User {user_id} not found")

# Global handler
@app.exception_handler(IntegrityError)
async def integrity_error_handler(request: Request, exc: IntegrityError):
    return JSONResponse(
        status_code=400,
        content={"detail": "Database integrity error"}
    )
```

## Testing

**Rule:** Use TestClient with in-memory database. Override dependencies for testing.

```python
# tests/conftest.py
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}, poolclass=StaticPool)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture
def client():
    Base.metadata.create_all(bind=engine)
    yield TestClient(app)
    Base.metadata.drop_all(bind=engine)

# tests/test_users.py
def test_create_user(client):
    response = client.post("/api/users", json={
        "email": "test@example.com",
        "username": "testuser",
        "password": "Test123!"
    })
    assert response.status_code == 201
    assert response.json()["email"] == "test@example.com"
    assert "hashed_password" not in response.json()

def test_create_duplicate_email(client, test_user):
    response = client.post("/api/users", json={
        "email": test_user["email"],
        "username": "different",
        "password": "Test123!"
    })
    assert response.status_code == 400
    assert "already registered" in response.json()["detail"]
```

## API Design

**Rule:** Follow RESTful conventions. Use status codes correctly. Document with OpenAPI.

```python
# RESTful endpoints
# GET /api/users - List users
# GET /api/users/{id} - Get user
# POST /api/users - Create user
# PATCH /api/users/{id} - Update user
# DELETE /api/users/{id} - Delete user

@router.post(
    "/users",
    response_model=UserResponse,
    status_code=201,
    summary="Create user",
    responses={
        201: {"description": "User created"},
        400: {"description": "Invalid input"},
        422: {"description": "Validation error"}
    }
)
async def create_user(user: UserCreate):
    """Create user with email, username, and password."""
    pass
```

## Database Integration

**Rule:** Use async SQLAlchemy with proper session management. Apply indexes to frequently queried fields.

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

engine = create_async_engine(DATABASE_URL, echo=False)
async_session_maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# Model with indexes
class User(Base):
    __tablename__ = "users"
    __table_args__ = (
        Index('idx_email', 'email'),
        Index('idx_username', 'username'),
    )

    id = Column(Integer, primary_key=True)
    email = Column(String, unique=True, nullable=False)
    username = Column(String, unique=True, nullable=False)
```

## Authentication

**Rule:** Use JWT tokens. Validate tokens in dependencies. Never expose sensitive data in responses.

```python
from jose import jwt
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_jwt(user_id: int) -> str:
    payload = {"user_id": user_id, "exp": datetime.utcnow() + timedelta(days=7)}
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def hash_password(password: str) -> str:
    return pwd_context.hash(password)
```

## Performance

**Rule:** Use async for all I/O. Implement response caching for static data. Use database connection pooling.

```python
# Concurrent operations
users, posts = await asyncio.gather(
    fetch_users(),
    fetch_posts()
)

# Database pooling (asyncpg recommended)
engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,
    max_overflow=0
)
```

## Related Resources

- `languages/python/testing.md` - Python testing patterns
- `languages/python/coding-standards.md` - Python style guide
- `base/api-design.md` - API design principles
- `base/testing-philosophy.md` - Testing strategies
