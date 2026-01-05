# Configuration Management

> **When to apply:** All applications requiring environment-specific configuration

Best practices for managing application configuration across environments.

## Core Principles

### Twelve-Factor Config Rule

Store configuration in environment variables, never in code.

**Configuration includes:**
- Database credentials, connection strings
- API keys, authentication tokens
- External service URLs, endpoints
- Feature flags
- Environment-specific settings (timeouts, limits)
- Resource identifiers (bucket names, queue names)

**Not configuration:**
- Application code, internal constants
- Dependency declarations, route definitions

### Requirements

1. **Environment-independent** - Same codebase works everywhere
2. **Never committed** - No secrets in version control
3. **Validated early** - Fail fast on missing/invalid config
4. **Type-safe** - Catch errors at startup, not runtime
5. **Documented** - Clear purpose for each value
6. **Minimal** - Only externalize what varies

---

## Environment Variables

### Basic Patterns

**Python:**
```python
import os
from dotenv import load_dotenv

load_dotenv()  # Loads from .env file

# Required - raises KeyError if missing
DATABASE_URL = os.environ['DATABASE_URL']

# Optional with default
API_TIMEOUT = int(os.environ.get('API_TIMEOUT', '30'))
DEBUG_MODE = os.environ.get('DEBUG', 'false').lower() == 'true'
```

**TypeScript:**
```typescript
import dotenv from 'dotenv';
dotenv.config();

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) throw new Error('DATABASE_URL required');

const API_TIMEOUT = parseInt(process.env.API_TIMEOUT || '30', 10);
const DEBUG_MODE = process.env.DEBUG === 'true';
```

**Go:**
```go
func MustGetEnv(key string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    panic(fmt.Sprintf("%s required", key))
}

var DatabaseURL = MustGetEnv("DATABASE_URL")
```

### Environment Files

**.env (local only - NEVER commit):**
```bash
DATABASE_URL=postgresql://localhost/myapp_dev
STRIPE_API_KEY=sk_test_12345
DEBUG=true
LOG_LEVEL=debug
```

**.env.example (commit as template):**
```bash
DATABASE_URL=postgresql://user:password@localhost/dbname
STRIPE_API_KEY=your_stripe_key_here
DEBUG=false
LOG_LEVEL=info
```

**.gitignore:**
```
.env
.env.local
.env.*.local
!.env.example
```

---

## Configuration Files vs Environment Variables

| Use Environment Variables | Use Configuration Files |
|--------------------------|-------------------------|
| Secrets and credentials  | Complex nested structures |
| Environment-specific values | Application defaults |
| Deployment configuration | Feature definitions |
| External service URLs    | Business logic config |

### Hierarchical Configuration

**config/default.yml:**
```yaml
app:
  name: MyApp
  port: 3000
  timeout: 30

database:
  pool_size: 10

features:
  new_dashboard: false
```

**config/production.yml:**
```yaml
app:
  port: ${PORT}
  timeout: 60

database:
  pool_size: 50

features:
  new_dashboard: true
```

---

## Type-Safe Configuration

### Python - pydantic-settings

```python
from pydantic_settings import BaseSettings
from pydantic import Field, PostgresDsn

class Settings(BaseSettings):
    database_url: PostgresDsn
    stripe_api_key: str
    debug: bool = False
    log_level: str = Field(default="info", pattern="^(debug|info|warning|error)$")
    api_timeout: int = Field(default=30, ge=1, le=300)

    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()  # Validates on load
```

### TypeScript - zod

```typescript
import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const configSchema = z.object({
  DATABASE_URL: z.string().url(),
  STRIPE_API_KEY: z.string().min(1),
  DEBUG: z.enum(['true', 'false']).transform(val => val === 'true'),
  LOG_LEVEL: z.enum(['debug', 'info', 'warning', 'error']).default('info'),
  API_TIMEOUT: z.string().transform(Number).pipe(z.number().min(1).max(300)).default('30'),
});

export const config = configSchema.parse(process.env);
```

### Go - viper

```go
type Config struct {
    Database DatabaseConfig
    API      APIConfig
}

func Load() (*Config, error) {
    viper.SetConfigName("config")
    viper.AddConfigPath("./config")
    viper.AutomaticEnv()
    viper.SetDefault("api.timeout", 30)

    if err := viper.ReadInConfig(); err != nil {
        return nil, err
    }

    var config Config
    return &config, viper.Unmarshal(&config)
}
```

---

## Secrets Management

### Never Hardcode

```python
# ❌ NEVER
API_KEY = "sk_live_abc123xyz789"

# ✅ ALWAYS
API_KEY = os.environ['API_KEY']

# ✅ BEST - Use IAM roles when possible
import boto3
s3 = boto3.client('s3')  # No credentials needed
```

### Cloud Secret Services

**AWS Secrets Manager:**
```python
import boto3
import json

def get_secret(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

db_creds = get_secret('prod/database/credentials')
```

**AWS Parameter Store:**
```python
ssm = boto3.client('ssm')

def get_parameter(name, decrypt=True):
    response = ssm.get_parameter(Name=name, WithDecryption=decrypt)
    return response['Parameter']['Value']

api_key = get_parameter('/myapp/prod/api-key')
```

**GCP Secret Manager:**
```python
from google.cloud import secretmanager

def get_secret(project_id, secret_id):
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode('UTF-8')
```

---

## Environment-Specific Configuration

### Multi-Environment Setup

```
config/
  ├── default.yml       # Base defaults
  ├── development.yml   # Dev overrides
  ├── test.yml         # Test overrides
  ├── staging.yml      # Staging overrides
  └── production.yml   # Production overrides
```

**Loading Strategy:**
```python
import os
import yaml

def load_config():
    env = os.environ.get('APP_ENV', 'development')

    with open('config/default.yml') as f:
        config = yaml.safe_load(f)

    env_path = f'config/{env}.yml'
    if Path(env_path).exists():
        with open(env_path) as f:
            config = deep_merge(config, yaml.safe_load(f))

    # Environment variables override everything
    config['database']['url'] = os.environ.get('DATABASE_URL', config['database']['url'])
    config['api']['key'] = os.environ['API_KEY']  # Required

    return config
```

### Feature Flags

```python
class FeatureFlags:
    def __init__(self):
        self.environment = os.environ.get('APP_ENV', 'development')

    def is_enabled(self, feature_name: str) -> bool:
        # Environment variable override
        env_var = f"FEATURE_{feature_name.upper()}"
        if env_var in os.environ:
            return os.environ[env_var].lower() == 'true'

        # Default by environment
        features = {
            'development': {'new_dashboard': True, 'beta': True},
            'staging': {'new_dashboard': True, 'beta': True},
            'production': {'new_dashboard': True, 'beta': False}
        }
        return features.get(self.environment, {}).get(feature_name, False)
```

---

## Environment Comparison

| Aspect | Development | Staging | Production |
|--------|-------------|---------|------------|
| Instance Count | 1 | 2 | 5+ |
| Instance Type | t3.small | t3.medium | t3.large+ |
| Database | db.t3.micro | db.t3.small | db.r5.xlarge+ |
| Debug Mode | Enabled | Disabled | Disabled |
| Log Level | debug | info | warning |
| Beta Features | Enabled | Enabled | Disabled |
| Secret Storage | .env file | Parameter Store | Secrets Manager |
| Auto-scaling | Disabled | Enabled | Enabled |

---

## Validation & Testing

### Fail Fast on Startup

```python
from pydantic import BaseSettings, validator, Field

class Settings(BaseSettings):
    database_url: str
    log_level: str
    api_timeout: int = Field(ge=1, le=300)

    @validator('log_level')
    def validate_log_level(cls, v):
        if v.lower() not in ['debug', 'info', 'warning', 'error']:
            raise ValueError(f'Invalid log_level: {v}')
        return v.lower()

    @validator('database_url')
    def validate_database_url(cls, v):
        if not v.startswith(('postgresql://', 'mysql://')):
            raise ValueError('Invalid database URL')
        return v

try:
    settings = Settings()
except Exception as e:
    print(f"Configuration error: {e}")
    sys.exit(1)
```

### Configuration Tests

```python
import pytest

def test_valid_config(monkeypatch):
    monkeypatch.setenv('DATABASE_URL', 'postgresql://localhost/test')
    monkeypatch.setenv('API_KEY', 'test-key')
    settings = Settings()
    assert settings.database_url == 'postgresql://localhost/test'

def test_missing_required_field(monkeypatch):
    monkeypatch.delenv('DATABASE_URL', raising=False)
    with pytest.raises(ValueError):
        Settings()

def test_invalid_value(monkeypatch):
    monkeypatch.setenv('API_TIMEOUT', '-1')
    with pytest.raises(ValueError):
        Settings()
```

---

## Infrastructure as Code

### Terraform Environment Configs

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

locals {
  configs = {
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
  config = local.configs[var.environment]
}
```

---

## Checklist

### Configuration
- [ ] No secrets in version control
- [ ] `.env.example` template exists
- [ ] Environment variables for environment-specific config
- [ ] Validation on startup
- [ ] Type-safe with validation library
- [ ] Clear error messages for missing/invalid config

### Secrets
- [ ] Cloud secret management system used
- [ ] No hardcoded credentials
- [ ] Regular secret rotation (30-90 days)
- [ ] Least privilege access
- [ ] Secret access audit logging

### Environments
- [ ] Same codebase for all environments
- [ ] Externalized environment-specific config
- [ ] Feature flags for gradual rollouts
- [ ] Infrastructure as Code
- [ ] Environment differences documented

---

## Related Resources

- `base/12-factor-app.md` - Factor III (Config) details
- `cloud/aws/security-best-practices.md` - AWS secrets
- `base/cicd-comprehensive.md` - CI/CD configuration
- [12-Factor App Config](https://12factor.net/config)
- [OWASP Secure Configuration](https://cheatsheetseries.owasp.org/cheatsheets/Secure_Cloud_Architecture_Cheat_Sheet.html)
