# Django Best Practices

> **When to apply:** All Python applications using Django framework
> **Framework:** Django 4.2+, Django REST Framework 3.14+
> **Language:** Python 3.11+

Production-ready Django development with models, views, DRF APIs, testing, and performance optimization.

## Project Structure

```
myproject/
├── manage.py
├── myproject/              # Project config
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

**Rule:** Use Meta class for ordering and indexes. Add `__str__` for string representation. Use verbose names.

```python
from django.db import models
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

    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True, max_length=200)
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

## Custom QuerySets

**Rule:** Use custom managers and querysets for reusable queries.

```python
class PostQuerySet(models.QuerySet):
    """Custom queryset for Post model."""

    def published(self):
        return self.filter(is_published=True)

    def by_author(self, author):
        return self.filter(author=author)


class Post(models.Model):
    objects = PostQuerySet.as_manager()

# Usage
published_posts = Post.objects.published()
author_posts = Post.objects.by_author(user).published()
```

## Class-Based Views

**Rule:** Use generic views. Override get_queryset for filtering. Use mixins for authentication.

```python
from django.views.generic import ListView, CreateView
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

**Rule:** Use ModelSerializer. Define read-only fields. Add custom validation.

```python
from rest_framework import serializers

class PostSerializer(serializers.ModelSerializer):
    """Serializer for Post model."""

    author_name = serializers.CharField(
        source='author.get_full_name',
        read_only=True
    )

    class Meta:
        model = Post
        fields = [
            'id', 'title', 'slug', 'content',
            'author', 'author_name',
            'created_at', 'is_published'
        ]
        read_only_fields = ['id', 'created_at', 'author']

    def validate_title(self, value: str) -> str:
        """Validate title length."""
        if len(value) < 5:
            raise serializers.ValidationError('Title must be at least 5 characters')
        return value
```

## ViewSets

**Rule:** Use ModelViewSet for CRUD. Filter queryset based on permissions. Add custom actions.

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

**Rule:** Use ModelForm. Add custom validation. Provide helpful widgets.

```python
from django import forms

class PostForm(forms.ModelForm):
    """Form for creating/editing posts."""

    class Meta:
        model = Post
        fields = ['title', 'content', 'is_published']
        widgets = {
            'content': forms.Textarea(attrs={'rows': 10}),
        }

    def clean_title(self) -> str:
        """Validate title is unique."""
        title = self.cleaned_data['title']
        if Post.objects.filter(title__iexact=title).exists():
            raise forms.ValidationError('A post with this title already exists')
        return title
```

## Testing

**Rule:** Use TestCase for database tests. Set up test data in setUp. Test both success and failure cases.

```python
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse

User = get_user_model()

# Model tests
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

# API tests
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
        data = {'title': 'Test Post', 'content': 'Test content'}

        response = self.client.post(url, data)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Post.objects.count(), 1)
        self.assertEqual(Post.objects.first().author, self.user)
```

## Settings Management

**Rule:** Split settings by environment. Use environment variables for secrets. Never commit secrets.

```python
# settings/base.py
from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = os.environ['SECRET_KEY']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
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

## Security Settings

**Rule:** Enable all security settings in production. Use HTTPS. Set secure cookie flags.

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

## Query Optimization

**Rule:** Use select_related for foreign keys. Use prefetch_related for many-to-many. Avoid N+1 queries.

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

## Database Indexes

**Rule:** Add indexes to frequently queried and filtered fields.

```python
class Post(models.Model):
    class Meta:
        indexes = [
            models.Index(fields=['created_at']),
            models.Index(fields=['author', 'is_published']),
        ]
```

## Middleware

**Rule:** Add unique request IDs. Handle exceptions globally. Process requests efficiently.

```python
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

## Signals

**Rule:** Use signals for cross-app communication. Clean up related data on delete.

```python
from django.db.models.signals import post_save, pre_delete
from django.dispatch import receiver
from django.core.cache import cache

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

## Admin Customization

**Rule:** Customize list display. Add filters and search. Optimize with select_related.

```python
from django.contrib import admin
from django.utils.html import format_html

@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    """Admin interface for Post model."""

    list_display = ['title', 'author', 'status_badge', 'created_at']
    list_filter = ['is_published', 'created_at']
    search_fields = ['title', 'content', 'author__username']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'created_at'

    fieldsets = (
        ('Content', {'fields': ('title', 'slug', 'content', 'author')}),
        ('Publication', {'fields': ('is_published',)}),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def status_badge(self, obj):
        """Display publication status with color."""
        if obj.is_published:
            return format_html('<span style="color: green;">Published</span>')
        return format_html('<span style="color: red;">Draft</span>')

    def get_queryset(self, request):
        """Optimize queryset with select_related."""
        return super().get_queryset(request).select_related('author')
```

## Caching

**Rule:** Cache expensive queries. Set appropriate timeouts. Invalidate on changes.

```python
from django.core.cache import cache
from django.views.decorators.cache import cache_page
from django.utils.decorators import method_decorator

# Function-based view caching
@cache_page(60 * 15)  # 15 minutes
def post_list(request):
    posts = Post.objects.published()
    return render(request, 'posts.html', {'posts': posts})

# Class-based view caching
class PostListView(ListView):
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
```

## Celery Tasks

**Rule:** Use async tasks for slow operations. Implement retry logic. Return meaningful results.

```python
from celery import shared_task
from django.core.mail import send_mail

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
        raise self.retry(exc=exc, countdown=60)
```

## Custom Permissions

**Rule:** Implement object-level permissions. Deny by default.

```python
from rest_framework import permissions

class IsAuthorOrReadOnly(permissions.BasePermission):
    """Allow authors to edit their own posts."""

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.author == request.user

# Usage
class PostViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthorOrReadOnly]
```

## Advanced Testing

**Rule:** Use Factory Boy for test data. Use pytest-django for modern testing.

```python
import pytest
import factory
from factory.django import DjangoModelFactory

# Factories
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


# Pytest tests
@pytest.mark.django_db
class TestPost:
    """Test Post model."""

    def test_create_post(self):
        """Test creating a post."""
        post = PostFactory()
        assert post.id is not None

    def test_published_queryset(self):
        """Test published posts queryset."""
        PostFactory(is_published=True)
        PostFactory(is_published=False)
        assert Post.objects.published().count() == 1
```

## Production Configuration

**Rule:** Use PostgreSQL in production. Configure logging. Use static file storage.

```python
# settings/production.py

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
            'maxBytes': 1024 * 1024 * 15,
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

## Related Resources

- `languages/python/coding-standards.md` - Python patterns
- `languages/python/testing.md` - Testing strategies
- `base/security-principles.md` - Security guidelines
