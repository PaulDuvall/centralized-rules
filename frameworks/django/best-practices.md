# Django Best Practices

> **Framework:** Django 4.2+
> **Applies to:** Django projects and Django REST Framework

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

## References

- **Django Documentation:** https://docs.djangoproject.com
- **Django REST Framework:** https://www.django-rest-framework.org
- **Two Scoops of Django:** https://www.feldroy.com/books/two-scoops-of-django-3-x
