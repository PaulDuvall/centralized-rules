# The Twelve-Factor App

Principles for building modern, cloud-native SaaS applications that are portable, scalable, and maintainable.

## Quick Reference

| Factor | Principle | Key Action |
|--------|-----------|------------|
| I. Codebase | One codebase, many deploys | Single Git repo, multiple environments |
| II. Dependencies | Explicitly declare and isolate | Use package.json, requirements.txt, go.mod |
| III. Config | Store config in environment | Environment variables, never hardcode |
| IV. Backing Services | Treat as attached resources | Access via URLs from config |
| V. Build, Release, Run | Strictly separate stages | Build once, deploy everywhere |
| VI. Processes | Execute as stateless processes | Store state in backing services |
| VII. Port Binding | Export services via port | Self-contained, no external server |
| VIII. Concurrency | Scale out via process model | Multiple instances, not bigger instances |
| IX. Disposability | Fast startup, graceful shutdown | Handle SIGTERM, idempotent operations |
| X. Dev/Prod Parity | Keep environments similar | Same databases, same tools |
| XI. Logs | Treat as event streams | stdout/stderr, never log files |
| XII. Admin Processes | Run as one-off processes | Same environment, same release |

---

## I. Codebase

**One codebase tracked in revision control, many deploys**

Single Git repository per application, multiple deployments (dev, staging, production) from same codebase.

**Implementation:**
```bash
my-app/
  .git/
  src/
  tests/
  infrastructure/

# Deploy different environments from tags
git tag v1.2.3
# dev: main branch, staging/prod: v1.2.3
```

**Anti-patterns:**
- Different repos for different environments
- Manual file copying
- Environment-specific branches that never merge

---

## II. Dependencies

**Explicitly declare and isolate dependencies**

Never rely on system packages. Declare all dependencies with exact versions.

**Implementation:**

| Language | Declaration | Isolation | Lock File |
|----------|-------------|-----------|-----------|
| Python | requirements.txt | virtualenv | requirements.txt |
| Node.js | package.json | npm/node_modules | package-lock.json |
| Go | go.mod | go modules | go.sum |
| Ruby | Gemfile | bundler | Gemfile.lock |

```python
# requirements.txt
Flask==2.3.0
SQLAlchemy==2.0.15

# Use isolation
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Anti-patterns:**
- Assuming system tools installed (curl, imagemagick)
- Global package installation
- Missing version constraints

---

## III. Config

**Store config in the environment**

Configuration varies between environments - use environment variables, never hardcode.

**What is Config:** Database URLs, API keys, feature flags, service hostnames

**Implementation:**
```bash
# .env (NEVER commit)
DATABASE_URL=postgresql://user:pass@localhost/mydb
API_KEY=super-secret-key

# .env.example (commit this)
DATABASE_URL=postgresql://user:password@localhost/dbname
API_KEY=your-api-key-here

# .gitignore
.env
```

```python
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.environ['DATABASE_URL']
API_KEY = os.environ.get('API_KEY', 'default-dev-key')
```

**Anti-patterns:**
- Hardcoded credentials in source
- Different branches for different environments
- Committed .env files
- Config files in version control (config.production.js)

**Test:** Can you open-source your code right now without leaking secrets?

---

## IV. Backing Services

**Treat backing services as attached resources**

No distinction between local and third-party services. All accessed via URL.

**Backing Services:** Databases, caches (Redis), message queues, SMTP, cloud storage (S3), external APIs

**Implementation:**
```python
# Service accessed via URL from environment
DATABASE_URL = os.environ['DATABASE_URL']
db = create_database_connection(DATABASE_URL)

# Swap without code change:
# Dev: DATABASE_URL=postgresql://localhost/mydb
# Prod: DATABASE_URL=postgresql://aws-rds-host/mydb
```

**Anti-patterns:**
- Hardcoded database hosts
- Different code paths for local vs production services

---

## V. Build, Release, Run

**Strictly separate build and run stages**

| Stage | Action | Output |
|-------|--------|--------|
| Build | Fetch dependencies, compile, test | Immutable artifact |
| Release | Build + environment config | Versioned release (v1.2.3) |
| Run | Execute release in environment | Running processes |

**Implementation:**
```bash
# BUILD: Create artifact
npm install && npm run build && npm test
docker build -t myapp:$GIT_SHA .

# RELEASE: Tag and store
docker tag myapp:$GIT_SHA myapp:v1.2.3
docker push myregistry/myapp:v1.2.3

# RUN: Execute in environment
docker run -e DATABASE_URL=$DB_URL myregistry/myapp:v1.2.3
```

**Key Requirements:**
- Build once, promote through environments
- Never modify code in release/run stages
- Version all releases uniquely
- Enable instant rollback

**Anti-patterns:**
- Recompiling in production
- Modifying files on production servers
- Environment-specific builds

---

## VI. Processes

**Execute as stateless processes**

Processes share nothing. Store persistent data in backing services.

**Implementation:**

**Bad (stateful):**
```python
class ShoppingCart:
    carts = {}  # Lost on restart!
```

**Good (stateless):**
```python
class ShoppingCart:
    def __init__(self):
        self.redis = redis.from_url(os.environ['REDIS_URL'])

    def add_item(self, user_id, item):
        self.redis.lpush(f'cart:{user_id}', json.dumps(item))
```

**Storage:**
```python
# Bad: Local disk
file.save('/var/uploads/file.jpg')

# Good: Object storage
s3_client.upload_fileobj(file, 'my-bucket', 'uploads/file.jpg')
```

**Benefits:** Horizontal scaling, no coordination needed, resilient to crashes

---

## VII. Port Binding

**Export services via port binding**

Self-contained application with embedded web server.

**Implementation:**
```python
# Python/Flask
port = int(os.environ.get('PORT', 5000))
app.run(host='0.0.0.0', port=port)
```

```javascript
// Node.js/Express
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Running on ${PORT}`));
```

**Anti-patterns:**
- Relying on pre-installed Apache/Nginx
- Hardcoded ports

---

## VIII. Concurrency

**Scale out via the process model**

Multiple process instances, not bigger instances.

**Process Types:**
```bash
# Procfile
web: gunicorn app:app --workers 4
worker: celery -A tasks worker
scheduler: celery -A tasks beat
```

**Scaling:**
```bash
# Heroku
heroku ps:scale web=3 worker=5

# Kubernetes
kubectl scale deployment web --replicas=3
```

**Anti-patterns:**
- Single monolithic process
- Only vertical scaling
- Manual process management

---

## IX. Disposability

**Maximize robustness with fast startup and graceful shutdown**

Processes can start/stop instantly without data loss.

**Implementation:**
```python
import signal, sys

def graceful_shutdown(signum, frame):
    print("Shutting down gracefully...")
    # Finish current requests
    # Close DB connections
    # Flush logs
    sys.exit(0)

signal.signal(signal.SIGTERM, graceful_shutdown)
```

**Idempotent Operations:**
```python
def process_order(order_id):
    order = db.get_order(order_id)
    if order.status == 'completed':
        return  # Safe to re-run

    # Process order
    order.status = 'completed'
    db.save(order)
```

**Benefits:** Elastic scaling, painless deployments, resilient to failures

---

## X. Dev/Prod Parity

**Keep development, staging, and production as similar as possible**

Minimize three gaps:
1. **Time gap:** Deploy frequently (hours, not weeks)
2. **Personnel gap:** Developers deploy their code
3. **Tools gap:** Same backing services in dev and prod

**Implementation:**
```yaml
# docker-compose.yml - matches production
services:
  web:
    build: .
    environment:
      DATABASE_URL: postgresql://postgres@db/myapp
      REDIS_URL: redis://redis:6379
  db:
    image: postgres:15  # Same as production
  redis:
    image: redis:7      # Same as production
```

**Anti-patterns:**
- SQLite in dev, PostgreSQL in prod
- Mock services in dev, real in prod
- Manual environment setup

---

## XI. Logs

**Treat logs as event streams**

Write to stdout/stderr. Never manage log files.

**Implementation:**
```python
import json, sys
from datetime import datetime

def log(level, message, **kwargs):
    print(json.dumps({
        'timestamp': datetime.utcnow().isoformat(),
        'level': level,
        'message': message,
        **kwargs
    }), file=sys.stdout)

log('INFO', 'User login', user_id=12345)
log('ERROR', 'DB timeout', error='connection failed')
```

**Environment Routing:**
- **Dev:** View directly in terminal
- **Docker:** Logs to CloudWatch/logging driver
- **Kubernetes:** stdout to Fluentd/Elasticsearch
- **Heroku:** stdout to Logplex

**Anti-patterns:**
- Writing to log files: `open('/var/log/app.log', 'a')`
- Custom log rotation
- Different formats per environment

---

## XII. Admin Processes

**Run admin/management tasks as one-off processes**

Admin tasks in same environment as app.

**Admin Tasks:** DB migrations, console/REPL, one-time scripts, scheduled jobs

**Implementation:**
```bash
# Database migration
heroku run python manage.py migrate
aws ecs run-task --task-definition myapp-migration

# Console access
heroku run python
>>> from myapp import db
>>> db.query(User).count()

# Scheduled task
0 2 * * * python manage.py send_daily_report
```

**Anti-patterns:**
- SSH into production to run scripts
- Different dependencies for admin tools
- Manual SQL on database

---

## Compliance Checklist

- [ ] Single repo, multiple deploys
- [ ] Explicit dependency declaration (package.json, requirements.txt)
- [ ] Environment variables for config
- [ ] Backing services via URLs
- [ ] Separate build/release/run stages
- [ ] Stateless processes
- [ ] Port binding, self-contained
- [ ] Scale via process instances
- [ ] Fast startup, graceful shutdown
- [ ] Same tools in dev and prod
- [ ] Logs to stdout/stderr
- [ ] Admin tasks as one-off processes

---

## AI/ML Systems Extension

### Additional Considerations for AI Workloads

**Data as a Dependency (extends Factor II):**
```python
# Version data like code
TRAINING_DATA_VERSION = os.environ['TRAINING_DATA_VERSION']
data_url = f's3://ml-data/training-{TRAINING_DATA_VERSION}.parquet'
```

**Model as Configuration (extends Factor III):**
```bash
MODEL_VERSION=v2.5.3
MODEL_ARTIFACT_URL=s3://ml-models/production/model-v2.5.3.pkl
```

**Stateless Inference (extends Factor VI):**
```python
# Never store prediction history in process memory
class StatelessPredictor:
    def __init__(self):
        self.model = load_model()
        self.db = connect_to_database(os.environ['DATABASE_URL'])

    def predict_and_store(self, input_data, user_id):
        prediction = self.model.predict(input_data)
        # Store in database, not process
        self.db.predictions.insert({
            'user_id': user_id,
            'prediction': prediction,
            'model_version': os.environ['MODEL_VERSION']
        })
        return prediction
```

**ML Pipeline Stages (extends Factor V):**
```bash
# BUILD: Train model
python train.py && python package_model.py

# RELEASE: Version and tag
aws s3 cp model.pkl s3://models/model-v${VERSION}.pkl

# RUN: Deploy to inference
docker run -e MODEL_VERSION=v${VERSION} inference:v${VERSION}
```

**ML-Specific Logging (extends Factor XI):**
```python
def log_prediction(input_data, prediction, model_version):
    print(json.dumps({
        'timestamp': datetime.utcnow().isoformat(),
        'event': 'prediction',
        'model_version': model_version,
        'prediction': prediction,
        'latency_ms': get_latency(),
        'confidence': get_confidence_score(prediction)
    }), file=sys.stdout)
```

### AI Systems Checklist

- [ ] Versioned training data in storage
- [ ] Model artifacts as immutable releases
- [ ] Stateless inference (no prediction history in memory)
- [ ] Model versions in environment variables
- [ ] Horizontal scaling for inference processes
- [ ] Model performance metrics logged to stdout
- [ ] Fallback strategy when model fails
- [ ] A/B testing for gradual rollouts
- [ ] Automated retraining as scheduled admin process

---

## Platform Support

- **Heroku:** Native twelve-factor support
- **AWS:** ECS, Elastic Beanstalk, App Runner, Lambda
- **Google Cloud:** Cloud Run, App Engine, GKE
- **Azure:** App Service, Container Instances, AKS
- **Platform-agnostic:** Docker + Kubernetes

---

## Resources

- Official 12-Factor: https://12factor.net
- AWS Well-Architected Framework: https://aws.amazon.com/architecture/well-architected/
- AWS ML Lens: https://docs.aws.amazon.com/wellarchitected/latest/machine-learning-lens/
- See `base/architecture-principles.md` for broader architectural guidance
- See `base/cicd-comprehensive.md` for deployment automation
- See `cloud/aws/well-architected.md` for AWS-specific guidance
