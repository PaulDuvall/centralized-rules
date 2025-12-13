# FastAPI Best Practices

> **When to apply:** All Python applications using FastAPI framework

Comprehensive guide to building production-ready FastAPI applications with async endpoints, Pydantic models, dependency injection, testing, and API design best practices.

## Table of Contents

- [Project Structure](#project-structure)
- [Async Endpoints](#async-endpoints)
- [Pydantic Models](#pydantic-models)
- [Dependency Injection](#dependency-injection)
- [Request Validation](#request-validation)
- [Error Handling](#error-handling)
- [Testing with TestClient](#testing-with-testclient)
- [API Design](#api-design)
- [Database Integration](#database-integration)
- [Authentication & Authorization](#authentication--authorization)
- [Performance Optimization](#performance-optimization)

---

## Project Structure

### Recommended Layout

```
myapp/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app instance
│   ├── config.py            # Configuration
│   ├── dependencies.py      # Shared dependencies
│   ├── models/              # Pydantic models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── post.py
│   ├── routers/             # API routes
│   │   ├── __init__.py
│   │   ├── users.py
│   │   └── posts.py
│   ├── services/            # Business logic
│   │   ├── __init__.py
│   │   ├── user_service.py
│   │   └── auth_service.py
│   ├── db/                  # Database
│   │   ├── __init__.py
│   │   ├── database.py      # SQLAlchemy setup
│   │   └── models.py        # ORM models
│   └── utils/
│       └── __init__.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_users.py
│   └── test_posts.py
├── alembic/                 # Database migrations
├── requirements.txt
└── .env.example
```

### Main Application Setup

**app/main.py:**
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import users, posts
from app.config import settings

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    docs_url="/api/docs" if settings.DEBUG else None,  # Disable docs in production
    redoc_url="/api/redoc" if settings.DEBUG else None,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(posts.router, prefix="/api/posts", tags=["posts"])

@app.get("/")
async def root():
    return {"message": "Welcome to FastAPI"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

---

## Async Endpoints

### When to Use Async

**Use `async def` for:**
- I/O-bound operations (database queries, HTTP requests, file I/O)
- Operations that can benefit from concurrency
- Most FastAPI endpoints

**Use regular `def` for:**
- CPU-bound operations
- Synchronous libraries without async support

### Async Best Practices

```python
from fastapi import APIRouter
import httpx
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

# ✅ Good: Async endpoint with async operations
@router.get("/users/{user_id}")
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    """Async database query"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# ✅ Good: Async HTTP request
@router.get("/external-api")
async def fetch_external_data():
    """Async HTTP client"""
    async with httpx.AsyncClient() as client:
        response = await client.get("https://api.example.com/data")
        return response.json()

# ✅ Good: Multiple concurrent operations
@router.get("/dashboard")
async def get_dashboard(db: AsyncSession = Depends(get_db)):
    """Fetch multiple resources concurrently"""
    import asyncio

    # Run queries concurrently
    users_task = db.execute(select(User).limit(10))
    posts_task = db.execute(select(Post).limit(10))
    stats_task = get_statistics()

    users_result, posts_result, stats = await asyncio.gather(
        users_task,
        posts_task,
        stats_task
    )

    return {
        "users": users_result.scalars().all(),
        "posts": posts_result.scalars().all(),
        "stats": stats
    }
```

---

## Pydantic Models

### Request and Response Models

```python
from pydantic import BaseModel, EmailStr, Field, validator
from datetime import datetime
from typing import Optional

# Base model
class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50, pattern="^[a-zA-Z0-9_-]+$")
    full_name: Optional[str] = None

# Request model (for creating users)
class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

    @validator('password')
    def validate_password_strength(cls, v):
        """Ensure password has required complexity"""
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least one digit')
        if not any(char.isupper() for char in v):
            raise ValueError('Password must contain at least one uppercase letter')
        return v

# Response model (what API returns)
class UserResponse(UserBase):
    id: int
    created_at: datetime
    is_active: bool

    class Config:
        from_attributes = True  # Allow ORM model conversion

# Update model (partial updates)
class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    full_name: Optional[str] = None

# Internal model (with sensitive data)
class UserInternal(UserResponse):
    hashed_password: str
```

### Using Models in Endpoints

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

@router.post("/users", response_model=UserResponse, status_code=201)
async def create_user(
    user: UserCreate,  # Request body automatically validated
    db: AsyncSession = Depends(get_db)
):
    """Create new user with automatic validation"""
    # Check if user exists
    existing = await db.execute(select(User).where(User.email == user.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    # Create user
    hashed_password = hash_password(user.password)
    db_user = User(
        email=user.email,
        username=user.username,
        full_name=user.full_name,
        hashed_password=hashed_password
    )
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)

    return db_user  # Automatically converted to UserResponse

@router.patch("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_update: UserUpdate,
    db: AsyncSession = Depends(get_db)
):
    """Partial update with exclude_unset"""
    result = await db.execute(select(User).where(User.id == user_id))
    db_user = result.scalar_one_or_none()

    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Only update fields that were provided
    update_data = user_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_user, field, value)

    await db.commit()
    await db.refresh(db_user)
    return db_user
```

---

## Dependency Injection

### Basic Dependencies

```python
from fastapi import Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Annotated

# Database session dependency
async def get_db() -> AsyncSession:
    """Provide database session"""
    async with async_session_maker() as session:
        try:
            yield session
        finally:
            await session.close()

# Current user dependency
async def get_current_user(
    token: Annotated[str, Header(alias="Authorization")],
    db: AsyncSession = Depends(get_db)
) -> User:
    """Extract and validate current user from token"""
    try:
        # Remove "Bearer " prefix
        token = token.replace("Bearer ", "")
        payload = decode_jwt(token)
        user_id = payload.get("user_id")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    return user

# Require active user
async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Ensure user is active"""
    if not current_user.is_active:
        raise HTTPException(status_code=403, detail="Inactive user")
    return current_user

# Require admin user
async def get_current_admin_user(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """Ensure user is admin"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return current_user
```

### Using Dependencies in Routes

```python
@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """Get current user profile - requires authentication"""
    return current_user

@router.post("/posts", response_model=PostResponse, status_code=201)
async def create_post(
    post: PostCreate,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Create post - requires authenticated user"""
    db_post = Post(**post.dict(), author_id=current_user.id)
    db.add(db_post)
    await db.commit()
    await db.refresh(db_post)
    return db_post

@router.delete("/users/{user_id}", status_code=204)
async def delete_user(
    user_id: int,
    admin_user: User = Depends(get_current_admin_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete user - requires admin"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    await db.delete(user)
    await db.commit()
```

### Dependency Classes

```python
from typing import Optional

class Pagination:
    """Reusable pagination dependency"""
    def __init__(
        self,
        skip: int = 0,
        limit: int = 100,
        max_limit: int = 1000
    ):
        if limit > max_limit:
            raise HTTPException(
                status_code=400,
                detail=f"Limit cannot exceed {max_limit}"
            )
        self.skip = skip
        self.limit = limit

class FilterParams:
    """Reusable filter dependency"""
    def __init__(
        self,
        search: Optional[str] = None,
        status: Optional[str] = None,
        created_after: Optional[datetime] = None
    ):
        self.search = search
        self.status = status
        self.created_after = created_after

# Usage
@router.get("/posts", response_model=list[PostResponse])
async def list_posts(
    pagination: Pagination = Depends(),
    filters: FilterParams = Depends(),
    db: AsyncSession = Depends(get_db)
):
    """List posts with pagination and filtering"""
    query = select(Post)

    if filters.search:
        query = query.where(Post.title.contains(filters.search))
    if filters.status:
        query = query.where(Post.status == filters.status)
    if filters.created_after:
        query = query.where(Post.created_at >= filters.created_after)

    query = query.offset(pagination.skip).limit(pagination.limit)

    result = await db.execute(query)
    return result.scalars().all()
```

---

## Request Validation

### Path Parameters

```python
from fastapi import Path

@router.get("/users/{user_id}")
async def get_user(
    user_id: int = Path(..., gt=0, description="The user ID")
):
    """Path parameter with validation"""
    pass

@router.get("/posts/{post_slug}")
async def get_post_by_slug(
    post_slug: str = Path(..., min_length=1, max_length=100, pattern="^[a-z0-9-]+$")
):
    """Slug must be lowercase alphanumeric with hyphens"""
    pass
```

### Query Parameters

```python
from fastapi import Query
from typing import Optional

@router.get("/search")
async def search(
    q: str = Query(..., min_length=3, max_length=100),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    sort_by: Optional[str] = Query(None, regex="^(created_at|title|author)$")
):
    """Search with validated query parameters"""
    pass
```

### Body Validation

```python
from pydantic import BaseModel, constr, conint

class CreatePost(BaseModel):
    title: constr(min_length=1, max_length=200)  # Constrained string
    content: constr(min_length=10)
    tags: list[str] = Field(default_factory=list, max_items=10)
    published: bool = False
    view_count: conint(ge=0) = 0  # Constrained integer

    @validator('tags', each_item=True)
    def validate_tags(cls, tag):
        """Validate each tag"""
        if len(tag) > 50:
            raise ValueError('Tag too long')
        return tag.lower()

@router.post("/posts", response_model=PostResponse)
async def create_post(post: CreatePost):
    """Request body automatically validated"""
    pass
```

---

## Error Handling

### Custom Exceptions

```python
from fastapi import HTTPException, status

class UserNotFoundError(HTTPException):
    def __init__(self, user_id: int):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} not found"
        )

class InsufficientPermissionsError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions"
        )
```

### Global Exception Handlers

```python
from fastapi import Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError

@app.exception_handler(IntegrityError)
async def integrity_error_handler(request: Request, exc: IntegrityError):
    """Handle database integrity errors"""
    return JSONResponse(
        status_code=400,
        content={"detail": "Database integrity error", "error": str(exc)}
    )

@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError):
    """Handle value errors"""
    return JSONResponse(
        status_code=400,
        content={"detail": str(exc)}
    )
```

---

## Testing with TestClient

### Basic Testing Setup

**tests/conftest.py:**
```python
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.db.database import Base, get_db
from app.db.models import User

# Test database (in-memory SQLite)
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(scope="function")
def client():
    """Test client with fresh database"""
    Base.metadata.create_all(bind=engine)
    yield TestClient(app)
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def test_user(client):
    """Create test user"""
    response = client.post(
        "/api/users",
        json={
            "email": "test@example.com",
            "username": "testuser",
            "password": "Test123!"
        }
    )
    return response.json()
```

### API Tests

**tests/test_users.py:**
```python
def test_create_user(client):
    """Test user creation"""
    response = client.post(
        "/api/users",
        json={
            "email": "newuser@example.com",
            "username": "newuser",
            "password": "SecurePass123!"
        }
    )

    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "newuser@example.com"
    assert data["username"] == "newuser"
    assert "id" in data
    assert "hashed_password" not in data  # Sensitive data excluded

def test_create_user_duplicate_email(client, test_user):
    """Test duplicate email rejection"""
    response = client.post(
        "/api/users",
        json={
            "email": test_user["email"],  # Duplicate
            "username": "different",
            "password": "SecurePass123!"
        }
    )

    assert response.status_code == 400
    assert "already registered" in response.json()["detail"]

def test_get_user(client, test_user):
    """Test get user by ID"""
    user_id = test_user["id"]
    response = client.get(f"/api/users/{user_id}")

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == user_id

def test_get_user_not_found(client):
    """Test 404 for non-existent user"""
    response = client.get("/api/users/99999")
    assert response.status_code == 404

def test_update_user(client, test_user):
    """Test user update"""
    user_id = test_user["id"]
    response = client.patch(
        f"/api/users/{user_id}",
        json={"full_name": "Updated Name"}
    )

    assert response.status_code == 200
    assert response.json()["full_name"] == "Updated Name"
```

### Testing with Authentication

```python
@pytest.fixture
def auth_headers(test_user):
    """Generate auth headers for test user"""
    token = create_jwt_token(test_user["id"])
    return {"Authorization": f"Bearer {token}"}

def test_get_current_user(client, auth_headers):
    """Test authenticated endpoint"""
    response = client.get("/api/me", headers=auth_headers)

    assert response.status_code == 200
    assert response.json()["email"] == "test@example.com"

def test_create_post_authenticated(client, auth_headers):
    """Test creating post requires authentication"""
    # Without auth
    response = client.post(
        "/api/posts",
        json={"title": "Test Post", "content": "Test content"}
    )
    assert response.status_code == 401

    # With auth
    response = client.post(
        "/api/posts",
        json={"title": "Test Post", "content": "Test content"},
        headers=auth_headers
    )
    assert response.status_code == 201
```

---

## API Design

### RESTful Conventions

```python
# GET /api/users - List users
# GET /api/users/{id} - Get specific user
# POST /api/users - Create user
# PUT /api/users/{id} - Replace user (full update)
# PATCH /api/users/{id} - Update user (partial update)
# DELETE /api/users/{id} - Delete user

# Nested resources
# GET /api/users/{id}/posts - List user's posts
# GET /api/posts/{id}/comments - List post's comments
```

### Versioning

```python
# URL versioning
@app.include_router(users_v1.router, prefix="/api/v1/users")
@app.include_router(users_v2.router, prefix="/api/v2/users")

# Header versioning
@router.get("/users")
async def list_users(accept_version: str = Header(default="v1")):
    if accept_version == "v2":
        return list_users_v2()
    return list_users_v1()
```

### OpenAPI Documentation

```python
@router.post(
    "/users",
    response_model=UserResponse,
    status_code=201,
    summary="Create new user",
    description="Create a new user account with email and password",
    response_description="The created user",
    tags=["users"],
    responses={
        201: {"description": "User created successfully"},
        400: {"description": "Invalid input or duplicate email"},
        422: {"description": "Validation error"}
    }
)
async def create_user(user: UserCreate):
    """
    Create a new user with the following information:

    - **email**: valid email address
    - **username**: 3-50 alphanumeric characters
    - **password**: minimum 8 characters with complexity requirements
    - **full_name**: optional full name
    """
    pass
```

---

## Related Resources

- **FastAPI Documentation:** https://fastapi.tiangolo.com/
- **Pydantic Documentation:** https://docs.pydantic.dev/
- See `languages/python/testing.md` for comprehensive Python testing
- See `languages/python/coding-standards.md` for Python best practices
- See `base/api-design.md` for general API design principles
- See `base/testing-philosophy.md` for testing strategies
