# Django Best Practices

> **When to apply:** All Python applications using Django framework
> **Framework:** Django 4.2+, Django REST Framework 3.14+
> **Language:** Python 3.11+

Best practices for building production-ready Django applications with models, views, DRF APIs, testing, and performance optimization.

## Project Structure

### Recommended Layout

```
myproject/
├── manage.py
├── myproject/              # Project config
│   ├── __init__.py
│   ├── settings/           # Split settings
│   │   ├── base.py
│   │   ├── development.py
│   │   └── production.py
│   ├── urls.py
│   └── wsgi.py
├── apps/                   # Django apps
│   ├── users/
│   ├── blog/
│   └── api/
├── static/
├── media/
├── templates/
└── requirements/
    ├── base.txt
    ├── development.txt
    └── production.txt
```

## Model Design

### Model Best Practices

```python
from django.db import models
from django.core.validators import MinValueValidator
from django.utils.translation import gettext_lazy as _

class Post(models.Model):
    """Blog post model."""

    class Meta:
        ordering = ['-created_at']
        verbose_name = _('post')
        verbose_name_plural = _('posts')
        indexes = [
            models.Index(fields=['-created_at']),
        ]

    title = models.CharField(
        max_length=200,
        help_text=_('Post title')
    )
    slug = models.SlugField(
        unique=True,
        max_length=200
    )
    content = models.TextField()
    author = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='posts'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_published = models.BooleanField(default=False)

    def __str__(self) -> str:
        return self.title

    def get_absolute_url(self) -> str:
        from django.urls import reverse
        return reverse('blog:post-detail', kwargs={'slug': self.slug})
```

### Manager Methods

```python
class PostQuerySet(models.QuerySet):
    """Custom queryset for Post model."""

    def published(self):
        return self.filter(is_published=True)

    def by_author(self, author):
        return self.filter(author=author)


class Post(models.Model):
    # ... fields ...

    objects = PostQuerySet.as_manager()

# Usage
published_posts = Post.objects.published()
author_posts = Post.objects.by_author(user).published()
```

## Views

### Class-Based Views

```python
from django.views.generic import ListView, DetailView, CreateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy

class PostListView(ListView):
    """Display list of published posts."""

    model = Post
    template_name = 'blog/post_list.html'
    context_object_name = 'posts'
    paginate_by = 10

    def get_queryset(self):
        return Post.objects.published()


class PostCreateView(LoginRequiredMixin, CreateView):
    """Create new post."""

    model = Post
    fields = ['title', 'content']
    template_name = 'blog/post_form.html'
    success_url = reverse_lazy('blog:post-list')

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)
```

## Django REST Framework

### Serializers

```python
from rest_framework import serializers
from .models import Post

class PostSerializer(serializers.ModelSerializer):
    """Serializer for Post model."""

    author_name = serializers.CharField(
        source='author.get_full_name',
        read_only=True
    )

    class Meta:
        model = Post
        fields = [
            'id',
            'title',
            'slug',
            'content',
            'author',
            'author_name',
            'created_at',
            'is_published',
        ]
        read_only_fields = ['id', 'created_at', 'author']

    def validate_title(self, value: str) -> str:
        """Validate title length."""
        if len(value) < 5:
            raise serializers.ValidationError(
                'Title must be at least 5 characters'
            )
        return value
```

### ViewSets

```python
from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response

class PostViewSet(viewsets.ModelViewSet):
    """API endpoint for posts."""

    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filterset_fields = ['author', 'is_published']
    search_fields = ['title', 'content']

    def get_queryset(self):
        queryset = super().get_queryset()
        if not self.request.user.is_staff:
            queryset = queryset.published()
        return queryset

    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        """Publish a post."""
        post = self.get_object()
        post.is_published = True
        post.save()
        return Response({'status': 'published'})
```

## Forms

### Model Forms

```python
from django import forms
from .models import Post

class PostForm(forms.ModelForm):
    """Form for creating/editing posts."""

    class Meta:
        model = Post
        fields = ['title', 'content', 'is_published']
        widgets = {
            'content': forms.Textarea(attrs={'rows': 10}),
        }

    def clean_title(self) -> str:
        """Validate and clean title."""
        title = self.cleaned_data['title']
        if Post.objects.filter(title__iexact=title).exists():
            raise forms.ValidationError(
                'A post with this title already exists'
            )
        return title
```

## Testing

### Model Tests

```python
from django.test import TestCase
from django.contrib.auth import get_user_model
from .models import Post

User = get_user_model()

class PostModelTest(TestCase):
    """Test Post model."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )

    def test_create_post(self):
        """Test creating a post."""
        post = Post.objects.create(
            title='Test Post',
            content='Test content',
            author=self.user
        )

        self.assertEqual(post.title, 'Test Post')
        self.assertEqual(post.author, self.user)
        self.assertFalse(post.is_published)

    def test_str_representation(self):
        """Test string representation."""
        post = Post.objects.create(
            title='Test Post',
            content='Content',
            author=self.user
        )

        self.assertEqual(str(post), 'Test Post')
```

### API Tests

```python
from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse

class PostAPITest(APITestCase):
    """Test Post API."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
        self.client.force_authenticate(user=self.user)

    def test_create_post(self):
        """Test creating post via API."""
        url = reverse('post-list')
        data = {
            'title': 'Test Post',
            'content': 'Test content'
        }

        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Post.objects.count(), 1)
        self.assertEqual(Post.objects.first().author, self.user)
```

## Settings Management

### Split Settings

```python
# settings/base.py
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = os.environ['SECRET_KEY']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    # ...
    'rest_framework',
    'apps.users',
    'apps.blog',
]

# settings/development.py
from .base import *

DEBUG = True
ALLOWED_HOSTS = ['localhost', '127.0.0.1']

# settings/production.py
from .base import *

DEBUG = False
ALLOWED_HOSTS = [os.environ['ALLOWED_HOST']]
```

## Security

### Security Checklist

```python
# settings/production.py

# HTTPS
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# HSTS
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Security headers
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'
```

## Performance

### Query Optimization

```python
# ❌ N+1 queries
for post in Post.objects.all():
    print(post.author.username)  # Database hit per post!

# ✅ Use select_related
posts = Post.objects.select_related('author').all()
for post in posts:
    print(post.author.username)  # Single query

# ✅ Use prefetch_related for many-to-many
posts = Post.objects.prefetch_related('tags').all()
```

### Database Indexes

```python
class Post(models.Model):
    class Meta:
        indexes = [
            models.Index(fields=['created_at']),
            models.Index(fields=['author', 'is_published']),
        ]
```

## Middleware

### Custom Middleware

```python
# middleware/request_id.py
import uuid
from django.utils.deprecation import MiddlewareMixin

class RequestIDMiddleware(MiddlewareMixin):
    """Add unique request ID to each request."""

    def process_request(self, request):
        request.id = str(uuid.uuid4())
        return None

    def process_response(self, request, response):
        if hasattr(request, 'id'):
            response['X-Request-ID'] = request.id
        return response
```

### Authentication Middleware

```python
# middleware/auth.py
from django.http import JsonResponse
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework_simplejwt.exceptions import TokenError

class JWTAuthenticationMiddleware:
    """Extract user from JWT token."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        auth_header = request.headers.get('Authorization', '')

        if auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
            try:
                access_token = AccessToken(token)
                request.user_id = access_token['user_id']
            except TokenError:
                pass

        return self.get_response(request)
```

## Signals

### Model Signals

```python
# signals.py
from django.db.models.signals import post_save, pre_delete
from django.dispatch import receiver
from django.core.cache import cache
from .models import Post

@receiver(post_save, sender=Post)
def clear_post_cache(sender, instance, created, **kwargs):
    """Clear cache when post is created or updated."""
    cache.delete(f'post_{instance.id}')
    cache.delete('post_list')

@receiver(pre_delete, sender=Post)
def cleanup_post_files(sender, instance, **kwargs):
    """Delete associated files before deleting post."""
    if instance.image:
        instance.image.delete(save=False)
```

### Custom Signals

```python
# signals.py
from django.dispatch import Signal

# Define custom signal
post_published = Signal()

# In model or view
class Post(models.Model):
    def publish(self):
        self.is_published = True
        self.save()

        # Send signal
        post_published.send(
            sender=self.__class__,
            instance=self,
            user=self.author
        )

# In receivers.py
from .signals import post_published

@receiver(post_published)
def notify_subscribers(sender, instance, user, **kwargs):
    """Notify subscribers when post is published."""
    # Send notifications
    pass
```

## Admin Customization

### ModelAdmin Best Practices

```python
# admin.py
from django.contrib import admin
from django.utils.html import format_html
from .models import Post

@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    """Admin interface for Post model."""

    list_display = ['title', 'author', 'status_badge', 'created_at']
    list_filter = ['is_published', 'created_at']
    search_fields = ['title', 'content', 'author__username']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'created_at'

    fieldsets = (
        ('Content', {
            'fields': ('title', 'slug', 'content', 'author')
        }),
        ('Publication', {
            'fields': ('is_published',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def status_badge(self, obj):
        """Display publication status with color."""
        if obj.is_published:
            color = 'green'
            text = 'Published'
        else:
            color = 'red'
            text = 'Draft'

        return format_html(
            '<span style="color: {};">{}</span>',
            color,
            text
        )
    status_badge.short_description = 'Status'

    def get_queryset(self, request):
        """Optimize queryset with select_related."""
        qs = super().get_queryset(request)
        return qs.select_related('author')
```

## Caching

### Cache Patterns

```python
from django.core.cache import cache
from django.views.decorators.cache import cache_page
from django.utils.decorators import method_decorator

# Function-based view caching
@cache_page(60 * 15)  # Cache for 15 minutes
def post_list(request):
    posts = Post.objects.published()
    return render(request, 'posts.html', {'posts': posts})

# Class-based view caching
class PostListView(ListView):
    model = Post

    @method_decorator(cache_page(60 * 15))
    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)

# Manual caching
def get_post(post_id: int) -> Post:
    """Get post with caching."""
    cache_key = f'post_{post_id}'
    post = cache.get(cache_key)

    if post is None:
        post = Post.objects.select_related('author').get(id=post_id)
        cache.set(cache_key, post, 60 * 15)

    return post

# Template fragment caching
{% load cache %}
{% cache 500 post_sidebar post.id %}
    <div class="sidebar">
        {{ post.related_posts }}
    </div>
{% endcache %}
```

### Cache Invalidation

```python
from django.db.models.signals import post_save
from django.core.cache import cache

@receiver(post_save, sender=Post)
def invalidate_post_cache(sender, instance, **kwargs):
    """Invalidate cache on post save."""
    cache.delete(f'post_{instance.id}')
    cache.delete('post_list')

    # Invalidate related caches
    cache.delete(f'author_{instance.author_id}_posts')
```

## Async and Background Tasks

### Celery Tasks

```python
# tasks.py
from celery import shared_task
from django.core.mail import send_mail
from .models import Post

@shared_task
def send_notification_email(post_id: int):
    """Send email notification for new post."""
    try:
        post = Post.objects.get(id=post_id)

        send_mail(
            subject=f'New Post: {post.title}',
            message=post.content[:200],
            from_email='noreply@example.com',
            recipient_list=['subscribers@example.com'],
            fail_silently=False,
        )

        return f'Email sent for post {post_id}'
    except Post.DoesNotExist:
        return f'Post {post_id} not found'

@shared_task(bind=True, max_retries=3)
def process_image(self, post_id: int):
    """Process post image with retry logic."""
    try:
        post = Post.objects.get(id=post_id)
        # Process image
        return f'Image processed for post {post_id}'
    except Exception as exc:
        # Retry after 60 seconds
        raise self.retry(exc=exc, countdown=60)

# Usage in views
from .tasks import send_notification_email

def publish_post(request, post_id):
    post = Post.objects.get(id=post_id)
    post.is_published = True
    post.save()

    # Queue background task
    send_notification_email.delay(post_id)

    return redirect('post-detail', pk=post_id)
```

## Advanced DRF Patterns

### Nested Serializers

```python
# serializers.py
from rest_framework import serializers

class CommentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Comment
        fields = ['id', 'content', 'author', 'created_at']

class PostDetailSerializer(serializers.ModelSerializer):
    """Detailed post serializer with nested comments."""

    comments = CommentSerializer(many=True, read_only=True)
    author_name = serializers.CharField(source='author.get_full_name', read_only=True)

    class Meta:
        model = Post
        fields = [
            'id', 'title', 'slug', 'content',
            'author', 'author_name',
            'comments', 'created_at', 'is_published'
        ]
```

### Custom Permissions

```python
# permissions.py
from rest_framework import permissions

class IsAuthorOrReadOnly(permissions.BasePermission):
    """Allow authors to edit their own posts."""

    def has_object_permission(self, request, view, obj):
        # Read permissions for any request
        if request.method in permissions.SAFE_METHODS:
            return True

        # Write permissions only for author
        return obj.author == request.user

# Usage in ViewSet
class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [IsAuthorOrReadOnly]
```

### Pagination

```python
# pagination.py
from rest_framework.pagination import PageNumberPagination

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

# settings.py
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'myapp.pagination.StandardResultsSetPagination',
}
```

## Advanced Testing

### Factory Pattern with Factory Boy

```python
# factories.py
import factory
from factory.django import DjangoModelFactory
from .models import Post, User

class UserFactory(DjangoModelFactory):
    class Meta:
        model = User

    username = factory.Sequence(lambda n: f'user{n}')
    email = factory.LazyAttribute(lambda obj: f'{obj.username}@example.com')

class PostFactory(DjangoModelFactory):
    class Meta:
        model = Post

    title = factory.Sequence(lambda n: f'Post {n}')
    content = factory.Faker('paragraph')
    author = factory.SubFactory(UserFactory)

# Usage in tests
from .factories import PostFactory, UserFactory

class PostTest(TestCase):
    def test_create_post(self):
        user = UserFactory()
        post = PostFactory(author=user)

        self.assertEqual(post.author, user)
```

### Pytest-Django

```python
# tests/test_models.py
import pytest
from myapp.models import Post
from myapp.factories import UserFactory, PostFactory

@pytest.mark.django_db
class TestPost:
    """Test Post model."""

    def test_create_post(self):
        """Test creating a post."""
        post = PostFactory()
        assert post.id is not None
        assert post.title.startswith('Post')

    def test_published_queryset(self):
        """Test published posts queryset."""
        PostFactory(is_published=True)
        PostFactory(is_published=False)

        published = Post.objects.published()
        assert published.count() == 1

# conftest.py
import pytest
from rest_framework.test import APIClient

@pytest.fixture
def api_client():
    """Provide API client for tests."""
    return APIClient()

@pytest.fixture
def authenticated_client(api_client, user):
    """Provide authenticated API client."""
    api_client.force_authenticate(user=user)
    return api_client
```

## Deployment

### Production Settings

```python
# settings/production.py
import os
from .base import *

DEBUG = False

ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ['DB_NAME'],
        'USER': os.environ['DB_USER'],
        'PASSWORD': os.environ['DB_PASSWORD'],
        'HOST': os.environ['DB_HOST'],
        'PORT': os.environ.get('DB_PORT', '5432'),
        'CONN_MAX_AGE': 600,
    }
}

# Static files
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media files
DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
AWS_STORAGE_BUCKET_NAME = os.environ['AWS_STORAGE_BUCKET_NAME']

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/var/log/django/app.log',
            'maxBytes': 1024 * 1024 * 15,  # 15MB
            'backupCount': 10,
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['file'],
        'level': 'INFO',
    },
}
```

### Docker Configuration

```dockerfile
# Dockerfile
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "myproject.wsgi:application"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build: .
    command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

## Related Resources

- See `languages/python/coding-standards.md` for Python patterns
- See `languages/python/testing.md` for testing strategies
- See `base/security-principles.md` for security guidelines

## References

- **Django Documentation:** https://docs.djangoproject.com
- **Django REST Framework:** https://www.django-rest-framework.org
- **Two Scoops of Django:** https://www.feldroy.com/products/two-scoops-of-django-3-x
