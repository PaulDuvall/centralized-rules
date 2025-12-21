# Configuration Management

> **When to apply:** All applications requiring environment-specific configuration

Best practices for managing application configuration across environments, ensuring security, maintainability, and consistency.

## Table of Contents

- [Core Principles](#core-principles)
- [Environment Variables](#environment-variables)
- [Configuration Files](#configuration-files)
- [Secrets Management](#secrets-management)
- [Environment-Specific Patterns](#environment-specific-patterns)
- [Validation and Type Safety](#validation-and-type-safety)
- [Configuration as Code](#configuration-as-code)

---

## Core Principles

### The Twelve-Factor Config Rule

**Rule:** Configuration should be stored in environment variables, never in code.

**What is Configuration:**
- Database credentials and connection strings
- API keys and authentication tokens
- External service URLs and endpoints
- Feature flags and toggles
- Environment-specific settings (timeouts, limits, batch sizes)
- Resource identifiers (bucket names, queue names)

**What is NOT Configuration:**
- Application code
- Internal constants (unchanging values)
- Dependency declarations
- Route definitions

### Configuration Should Be:

1. **Environment-independent:** Same codebase works in dev, staging, production
2. **Never committed:** No secrets in version control
3. **Validated early:** Fail fast on missing/invalid config
4. **Type-safe:** Catch configuration errors at startup, not runtime
5. **Documented:** Clear what each config value does
6. **Minimal:** Only externalize what truly varies between environments

---

## Environment Variables

### Basic Usage

**Python:**
```python
import os

# Required configuration
DATABASE_URL = os.environ['DATABASE_URL']  # Raises KeyError if missing

# Optional with default
API_TIMEOUT = int(os.environ.get('API_TIMEOUT', '30'))
DEBUG_MODE = os.environ.get('DEBUG', 'false').lower() == 'true'

# Using dotenv for local development
from dotenv import load_dotenv
load_dotenv()  # Loads from .env file

DATABASE_URL = os.environ['DATABASE_URL']
```

**TypeScript/Node.js:**
```typescript
// Required configuration
const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  throw new Error('DATABASE_URL environment variable is required');
}

// Optional with default
const API_TIMEOUT = parseInt(process.env.API_TIMEOUT || '30', 10);
const DEBUG_MODE = process.env.DEBUG === 'true';

// Using dotenv
import dotenv from 'dotenv';
dotenv.config();
```

**Go:**
```go
package config

import (
    "os"
    "strconv"
)

func MustGetEnv(key string) string {
    value := os.Getenv(key)
    if value == "" {
        panic(fmt.Sprintf("Environment variable %s is required", key))
    }
    return value
}

func GetEnvInt(key string, defaultValue int) int {
    if value := os.Getenv(key); value != "" {
        if intValue, err := strconv.Atoi(value); err == nil {
            return intValue
        }
    }
    return defaultValue
}

// Usage
var (
    DatabaseURL = MustGetEnv("DATABASE_URL")
    APITimeout  = GetEnvInt("API_TIMEOUT", 30)
    DebugMode   = os.Getenv("DEBUG") == "true"
)
```

### Environment File Management

**.env (local development only - NEVER commit):**
```bash
# Database
DATABASE_URL=postgresql://localhost/myapp_dev
REDIS_URL=redis://localhost:6379

# External Services
STRIPE_API_KEY=sk_test_12345
SENDGRID_API_KEY=SG.abc123

# App Config
DEBUG=true
LOG_LEVEL=debug
API_TIMEOUT=30
```

**.env.example (commit this as template):**
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost/dbname
REDIS_URL=redis://localhost:6379

# External Services
STRIPE_API_KEY=your_stripe_key_here
SENDGRID_API_KEY=your_sendgrid_key_here

# App Config
DEBUG=false
LOG_LEVEL=info
API_TIMEOUT=30
```

**.gitignore:**
```
.env
.env.local
.env.*.local
*.env
!.env.example
```

---

## Configuration Files

### When to Use Configuration Files

**Use environment variables for:**
- Secrets and credentials
- Environment-specific values
- Deployment configuration

**Use configuration files for:**
- Complex nested structures
- Application defaults
- Feature definitions
- Business logic configuration

### Hierarchical Configuration

**config/default.yml (defaults):**
```yaml
app:
  name: MyApp
  version: 1.0.0
  port: 3000
  timeout: 30

database:
  pool_size: 10
  timeout: 5000

features:
  new_dashboard: false
  beta_features: false
```

**config/production.yml (overrides):**
```yaml
app:
  port: ${PORT}  # Environment variable
  timeout: 60

database:
  pool_size: 50
  timeout: 10000

features:
  new_dashboard: true
```

### Configuration Libraries

**Python - pydantic-settings:**
```python
from pydantic_settings import BaseSettings
from pydantic import Field, PostgresDsn, RedisDsn

class Settings(BaseSettings):
    """Application configuration with validation"""

    # Database
    database_url: PostgresDsn
    redis_url: RedisDsn

    # API Keys
    stripe_api_key: str
    sendgrid_api_key: str

    # App Config
    debug: bool = False
    log_level: str = Field(default="info", pattern="^(debug|info|warning|error)$")
    api_timeout: int = Field(default=30, ge=1, le=300)

    # Feature Flags
    enable_new_dashboard: bool = False
    max_upload_size_mb: int = Field(default=10, ge=1, le=100)

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False

# Usage
settings = Settings()  # Automatically loads from env vars and .env

# Type-safe access
db = create_connection(settings.database_url)
timeout = settings.api_timeout  # Guaranteed to be int
```

**TypeScript - zod + dotenv:**
```typescript
import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const configSchema = z.object({
  // Database
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url(),

  // API Keys
  STRIPE_API_KEY: z.string().min(1),
  SENDGRID_API_KEY: z.string().min(1),

  // App Config
  DEBUG: z.enum(['true', 'false']).transform((val) => val === 'true'),
  LOG_LEVEL: z.enum(['debug', 'info', 'warning', 'error']).default('info'),
  API_TIMEOUT: z.string().transform(Number).pipe(z.number().min(1).max(300)).default('30'),

  // Feature Flags
  ENABLE_NEW_DASHBOARD: z.enum(['true', 'false']).transform((val) => val === 'true').default('false'),
  MAX_UPLOAD_SIZE_MB: z.string().transform(Number).pipe(z.number().min(1).max(100)).default('10'),
});

// Parse and validate
export const config = configSchema.parse(process.env);

// Type-safe access (TypeScript knows all types)
const db = createConnection(config.DATABASE_URL);
const timeout = config.API_TIMEOUT;  // number
const debug = config.DEBUG;  // boolean
```

**Go - viper:**
```go
package config

import (
    "github.com/spf13/viper"
)

type Config struct {
    Database DatabaseConfig
    Redis    RedisConfig
    API      APIConfig
}

type DatabaseConfig struct {
    URL         string
    PoolSize    int
    Timeout     int
}

type APIConfig struct {
    Timeout    int
    LogLevel   string
    Debug      bool
}

func Load() (*Config, error) {
    viper.SetConfigName("config")
    viper.SetConfigType("yaml")
    viper.AddConfigPath("./config")
    viper.AddConfigPath(".")

    // Read from environment
    viper.AutomaticEnv()

    // Set defaults
    viper.SetDefault("api.timeout", 30)
    viper.SetDefault("api.log_level", "info")

    if err := viper.ReadInConfig(); err != nil {
        return nil, err
    }

    var config Config
    if err := viper.Unmarshal(&config); err != nil {
        return nil, err
    }

    return &config, nil
}
```

---

## Secrets Management

### Never Hardcode Secrets

**❌ Bad:**
```python
# NEVER do this
API_KEY = "sk_live_abc123xyz789"
DATABASE_PASSWORD = "SuperSecret123!"

# NEVER commit this
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCY"
```

**✅ Good:**
```python
import os

# From environment variables
API_KEY = os.environ['API_KEY']
DATABASE_PASSWORD = os.environ['DATABASE_PASSWORD']

# AWS credentials from IAM role (preferred) or environment
# boto3 automatically uses IAM role if available
import boto3
s3 = boto3.client('s3')  # No credentials needed!
```

### Cloud Secret Management

**AWS Secrets Manager:**
```python
import boto3
import json

def get_secret(secret_name):
    """Retrieve secret from AWS Secrets Manager"""
    client = boto3.client('secretsmanager', region_name='us-east-1')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

# Usage
db_credentials = get_secret('prod/database/credentials')
DATABASE_URL = f"postgresql://{db_credentials['username']}:{db_credentials['password']}@{db_credentials['host']}/{db_credentials['database']}"
```

**AWS Parameter Store:**
```python
import boto3

ssm = boto3.client('ssm', region_name='us-east-1')

def get_parameter(name, decrypt=True):
    """Get parameter from Parameter Store"""
    response = ssm.get_parameter(Name=name, WithDecryption=decrypt)
    return response['Parameter']['Value']

# Usage
api_key = get_parameter('/myapp/prod/api-key', decrypt=True)
database_url = get_parameter('/myapp/prod/database-url')
```

**Google Cloud Secret Manager:**
```python
from google.cloud import secretmanager

def get_secret(project_id, secret_id, version='latest'):
    """Retrieve secret from Google Cloud Secret Manager"""
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/{version}"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode('UTF-8')

# Usage
api_key = get_secret('my-project', 'stripe-api-key')
```

---

## Environment-Specific Patterns

### Multi-Environment Configuration

**Directory Structure:**
```
config/
  ├── default.yml          # Base defaults
  ├── development.yml      # Dev overrides
  ├── test.yml            # Test overrides
  ├── staging.yml         # Staging overrides
  └── production.yml      # Production overrides
```

**Loading Strategy:**
```python
import os
import yaml
from pathlib import Path

def load_config():
    """Load configuration with environment-specific overrides"""
    env = os.environ.get('APP_ENV', 'development')

    # Load base config
    with open('config/default.yml') as f:
        config = yaml.safe_load(f)

    # Load environment-specific config
    env_config_path = Path(f'config/{env}.yml')
    if env_config_path.exists():
        with open(env_config_path) as f:
            env_config = yaml.safe_load(f)
            # Deep merge env_config into config
            config = deep_merge(config, env_config)

    # Override with environment variables
    config['database']['url'] = os.environ.get('DATABASE_URL', config['database']['url'])
    config['api']['key'] = os.environ['API_KEY']  # Required

    return config
```

### Feature Flags

**Environment-Based:**
```python
class FeatureFlags:
    def __init__(self):
        self.environment = os.environ.get('APP_ENV', 'development')

    def is_enabled(self, feature_name: str) -> bool:
        """Check if feature is enabled"""
        # Check environment variable override first
        env_var = f"FEATURE_{feature_name.upper()}"
        if env_var in os.environ:
            return os.environ[env_var].lower() == 'true'

        # Default feature flags by environment
        features = {
            'development': {
                'new_dashboard': True,
                'beta_features': True,
                'debug_toolbar': True,
            },
            'staging': {
                'new_dashboard': True,
                'beta_features': True,
                'debug_toolbar': False,
            },
            'production': {
                'new_dashboard': True,
                'beta_features': False,
                'debug_toolbar': False,
            }
        }

        return features.get(self.environment, {}).get(feature_name, False)

# Usage
flags = FeatureFlags()
if flags.is_enabled('new_dashboard'):
    render_new_dashboard()
else:
    render_old_dashboard()
```

---

## Validation and Type Safety

### Fail Fast on Startup

**Python with pydantic:**
```python
from pydantic import BaseSettings, validator, Field

class Settings(BaseSettings):
    database_url: str
    redis_url: str
    api_timeout: int = Field(ge=1, le=300)  # Between 1 and 300
    log_level: str

    @validator('log_level')
    def validate_log_level(cls, v):
        allowed = ['debug', 'info', 'warning', 'error']
        if v.lower() not in allowed:
            raise ValueError(f'log_level must be one of {allowed}')
        return v.lower()

    @validator('database_url')
    def validate_database_url(cls, v):
        if not v.startswith(('postgresql://', 'mysql://')):
            raise ValueError('database_url must start with postgresql:// or mysql://')
        return v

# This will raise validation errors on startup if config is invalid
try:
    settings = Settings()
except Exception as e:
    print(f"Configuration error: {e}")
    sys.exit(1)
```

### Configuration Testing

```python
import pytest
from config import Settings

def test_settings_with_valid_config(monkeypatch):
    """Test configuration loads correctly"""
    monkeypatch.setenv('DATABASE_URL', 'postgresql://localhost/test')
    monkeypatch.setenv('REDIS_URL', 'redis://localhost:6379')
    monkeypatch.setenv('API_KEY', 'test-key')

    settings = Settings()

    assert settings.database_url == 'postgresql://localhost/test'
    assert settings.redis_url == 'redis://localhost:6379'

def test_settings_missing_required_field(monkeypatch):
    """Test that missing required fields raise errors"""
    monkeypatch.delenv('DATABASE_URL', raising=False)

    with pytest.raises(ValueError):
        Settings()

def test_settings_invalid_value(monkeypatch):
    """Test that invalid values raise errors"""
    monkeypatch.setenv('API_TIMEOUT', '-1')  # Invalid: must be >= 1

    with pytest.raises(ValueError):
        Settings()
```

---

## Configuration as Code

### Infrastructure as Configuration

**Terraform Variables:**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "app_config" {
  description = "Application configuration"
  type = object({
    instance_count = number
    instance_type  = string
    database_size  = string
  })
}

# Environment-specific configs
locals {
  environment_configs = {
    dev = {
      instance_count = 1
      instance_type  = "t3.small"
      database_size  = "db.t3.micro"
    }
    staging = {
      instance_count = 2
      instance_type  = "t3.medium"
      database_size  = "db.t3.small"
    }
    prod = {
      instance_count = 5
      instance_type  = "t3.large"
      database_size  = "db.r5.xlarge"
    }
  }

  config = local.environment_configs[var.environment]
}
```

### GitOps Configuration

**ArgoCD Application:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-prod
spec:
  source:
    repoURL: https://github.com/org/repo
    path: k8s/overlays/production
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## Best Practices Checklist

### Configuration Management
- [ ] No secrets committed to version control
- [ ] `.env.example` provides template for all required config
- [ ] Environment variables used for environment-specific config
- [ ] Configuration validated on application startup
- [ ] Type-safe configuration with validation
- [ ] Fail fast with clear error messages for missing/invalid config
- [ ] Configuration documented (what each value does)

### Secrets Management
- [ ] Secrets stored in dedicated secret management system
- [ ] No hardcoded credentials in code
- [ ] Secrets rotated regularly (30-90 days)
- [ ] Least privilege access to secrets
- [ ] Audit logging for secret access

### Environment Management
- [ ] Same codebase deploys to all environments
- [ ] Environment-specific config externalized
- [ ] Feature flags for gradual rollouts
- [ ] Infrastructure as Code for reproducibility
- [ ] Clear documentation of environment differences

---

## Related Resources

- See `base/12-factor-app.md` for Factor III (Config) detailed guidance
- See `cloud/aws/security-best-practices.md` for AWS secrets management
- See `base/cicd-comprehensive.md` for CI/CD configuration management
- **12-Factor App Config:** https://12factor.net/config
- **OWASP Secure Configuration:** https://cheatsheetseries.owasp.org/cheatsheets/Secure_Cloud_Architecture_Cheat_Sheet.html
