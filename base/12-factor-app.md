# The Twelve-Factor App

Principles for building modern, cloud-native SaaS applications. These methodologies ensure applications are portable, scalable, and maintainable across cloud platforms.

## Table of Contents

1. [Codebase](#i-codebase)
2. [Dependencies](#ii-dependencies)
3. [Config](#iii-config)
4. [Backing Services](#iv-backing-services)
5. [Build, Release, Run](#v-build-release-run)
6. [Processes](#vi-processes)
7. [Port Binding](#vii-port-binding)
8. [Concurrency](#viii-concurrency)
9. [Disposability](#ix-disposability)
10. [Dev/Prod Parity](#x-devprod-parity)
11. [Logs](#xi-logs)
12. [Admin Processes](#xii-admin-processes)

---

## I. Codebase

### One codebase tracked in revision control, many deploys

**Rule:** Use a single codebase per application, tracked in version control (Git), with multiple deployments from that codebase.

**Requirements:**
- All code, configuration templates, and infrastructure definitions in version control
- One Git repository per application/service
- Multiple environments (dev, staging, production) deploy from the same codebase
- Use branches/tags for different versions, not separate repositories

**Implementation:**
```bash
# Single repository structure
my-app/
  .git/
  src/
  tests/
  infrastructure/
  README.md

# Multiple deployments from same code
git tag v1.2.3
# Deploy to dev: latest main branch
# Deploy to staging: v1.2.3 tag
# Deploy to production: v1.2.3 tag
```

**Anti-patterns:**
- ❌ Different codebases for dev/staging/production
- ❌ Manual file copying instead of version control
- ❌ Environment-specific code branches that never merge

**Benefits:**
- Single source of truth
- Consistent behavior across environments
- Easier debugging and rollback

---

## II. Dependencies

### Explicitly declare and isolate dependencies

**Rule:** All dependencies must be explicitly declared and isolated from the system.

**Requirements:**
- Never rely on system-wide packages
- Use dependency declaration manifests (package.json, requirements.txt, go.mod, Gemfile)
- Use dependency isolation tools (virtualenv, bundler, go modules)
- Include exact version numbers or lock files
- Vendor dependencies for reproducible builds

**Implementation:**

**Python:**
```bash
# requirements.txt
Flask==2.3.0
SQLAlchemy==2.0.15
pytest==7.3.1

# Use virtual environment
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Node.js:**
```json
// package.json
{
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.0"
  },
  "devDependencies": {
    "jest": "^29.5.0"
  }
}

// Use lock file for deterministic installs
npm install  # Creates package-lock.json
```

**Go:**
```go
// go.mod
module myapp

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    gorm.io/gorm v1.25.1
)
```

**Anti-patterns:**
- ❌ Assuming curl or imagemagick is installed
- ❌ Global npm install without package.json
- ❌ System Python packages instead of virtualenv

---

## III. Config

### Store config in the environment

**Rule:** Configuration that varies between environments must be stored in environment variables, never in code.

**What is Config:**
- Database credentials and connection strings
- API keys and secrets
- Hostnames for external services
- Feature flags
- Environment-specific URLs

**Requirements:**
- Use environment variables for all config
- Never commit secrets to version control
- Use `.env` files locally (add to `.gitignore`)
- Use platform-specific secret management in production (AWS Secrets Manager, Parameter Store)
- Provide `.env.example` template without sensitive values

**Implementation:**

```bash
# .env (NEVER commit this)
DATABASE_URL=postgresql://user:pass@localhost/mydb
API_KEY=super-secret-key
REDIS_URL=redis://localhost:6379

# .env.example (commit this)
DATABASE_URL=postgresql://user:password@localhost/dbname
API_KEY=your-api-key-here
REDIS_URL=redis://localhost:6379

# .gitignore
.env
*.env
!.env.example
```

**Python:**
```python
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.environ['DATABASE_URL']
API_KEY = os.environ.get('API_KEY', 'default-dev-key')
```

**Node.js:**
```javascript
require('dotenv').config();

const config = {
  database: process.env.DATABASE_URL,
  apiKey: process.env.API_KEY,
  port: process.env.PORT || 3000
};
```

**Production (AWS):**
```bash
# Use AWS Systems Manager Parameter Store
aws ssm put-parameter --name /myapp/prod/database-url \
  --value "postgresql://..." --type SecureString

# Application retrieves at runtime
DATABASE_URL=$(aws ssm get-parameter --name /myapp/prod/database-url \
  --with-decryption --query 'Parameter.Value' --output text)
```

**Anti-patterns:**
- ❌ Hardcoded config in source files
- ❌ Different code branches for different environments
- ❌ Committed `.env` files with real credentials
- ❌ Config files in version control (config.production.js)

**Test: Can you open-source your code right now?** If secrets would leak, you're not twelve-factor compliant.

---

## IV. Backing Services

### Treat backing services as attached resources

**Rule:** Make no distinction between local and third-party services. Both are attached resources accessed via URL or locator.

**Backing Services:**
- Databases (PostgreSQL, MySQL, MongoDB)
- Caching systems (Redis, Memcached)
- Message queues (RabbitMQ, SQS, Kafka)
- SMTP services
- Cloud storage (S3, GCS)
- External APIs

**Requirements:**
- Access all services via config (URLs, credentials in environment)
- No code changes to swap service instances
- Services should be swappable without deploy

**Implementation:**
```python
# Service accessed via URL from environment
DATABASE_URL = os.environ['DATABASE_URL']
db = create_database_connection(DATABASE_URL)

# Swap from local to cloud without code change:
# Development: DATABASE_URL=postgresql://localhost/mydb
# Production:  DATABASE_URL=postgresql://aws-rds-host/mydb

# Swap from local SMTP to cloud service:
# Development: SMTP_URL=smtp://localhost:1025
# Production:  SMTP_URL=smtp://api.sendgrid.com
```

**Benefits:**
- Easy to swap resources (e.g., migrate from Postgres to Aurora)
- Test against production-like services locally
- Isolate failures to specific resources

**Anti-patterns:**
- ❌ Hardcoded database hosts in code
- ❌ Different code paths for local vs production services

---

## V. Build, Release, Run

### Strictly separate build and run stages

**Rule:** Transform codebase into deployable artifact through distinct stages.

**Three Stages:**

1. **Build Stage:** Convert code into executable bundle
   - Fetch dependencies
   - Compile assets
   - Run tests
   - Create immutable artifact

2. **Release Stage:** Combine build with environment config
   - Take build artifact
   - Inject environment-specific configuration
   - Create uniquely versioned release (v1.2.3, 20231201-5a3d2f)

3. **Run Stage:** Execute release in target environment
   - Launch processes
   - No code changes allowed

**Implementation:**

```bash
# Build stage (CI/CD)
npm install
npm run build
npm test
docker build -t myapp:$GIT_SHA .

# Release stage
# Artifact + Config = Release
docker tag myapp:$GIT_SHA myapp:v1.2.3
# Store in artifact registry
docker push myregistry/myapp:v1.2.3

# Run stage (in production)
docker pull myregistry/myapp:v1.2.3
docker run -e DATABASE_URL=$DB_URL myregistry/myapp:v1.2.3
```

**Requirements:**
- **Build artifacts once**, promote through environments
- **Never modify code** in release or run stages
- **Version all releases** uniquely and immutably
- **Enable rollback** to previous releases instantly

**Anti-patterns:**
- ❌ Recompiling code in production
- ❌ Modifying files directly on production servers
- ❌ Environment-specific build artifacts

**Benefits:**
- Reproducible deployments
- Fast rollbacks
- Confidence that tested artifact is what runs in production

---

## VI. Processes

### Execute the app as one or more stateless processes

**Rule:** Applications execute as stateless processes. Any persistent data must be stored in stateful backing services.

**Requirements:**
- Processes are stateless and share-nothing
- Never assume memory or filesystem will be available on next request
- Session state stored in backing service (Redis, database)
- No sticky sessions required

**Implementation:**

**Bad (stateful process):**
```python
# Anti-pattern: storing state in process memory
class ShoppingCart:
    carts = {}  # In-memory storage - lost on restart

    def add_item(self, user_id, item):
        if user_id not in self.carts:
            self.carts[user_id] = []
        self.carts[user_id].append(item)
```

**Good (stateless process):**
```python
# Store state in Redis backing service
import redis

class ShoppingCart:
    def __init__(self):
        self.redis = redis.from_url(os.environ['REDIS_URL'])

    def add_item(self, user_id, item):
        key = f'cart:{user_id}'
        self.redis.lpush(key, json.dumps(item))
```

**Filesystem:**
```python
# Bad: Store uploads on local disk
def upload_file(file):
    file.save('/var/uploads/file.jpg')  # Lost if instance terminates

# Good: Store in object storage (S3)
def upload_file(file):
    s3_client.upload_fileobj(file, 'my-bucket', 'uploads/file.jpg')
```

**Benefits:**
- Horizontal scaling (add more process instances)
- No coordination needed between processes
- Graceful restarts and deployments
- Resilient to process crashes

---

## VII. Port Binding

### Export services via port binding

**Rule:** The app is completely self-contained and exports services by binding to a port.

**Requirements:**
- Application includes web server (no external web server required)
- Listen on port provided via environment variable
- No reliance on runtime injection of web server

**Implementation:**

**Python (Flask):**
```python
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello, World!'

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
```

**Node.js (Express):**
```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => res.send('Hello, World!'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
```

**Deployment:**
```bash
# Development
PORT=5000 python app.py

# Production (AWS ECS, Cloud Run)
# Platform assigns PORT automatically
docker run -e PORT=8080 myapp
```

**One App Can Be Another's Backing Service:**
```
App A (binds to :5000) → App B's backing service (accessed via http://app-a:5000)
```

**Anti-patterns:**
- ❌ Relying on Apache/Nginx to be pre-installed
- ❌ Hardcoded port numbers

---

## VIII. Concurrency

### Scale out via the process model

**Rule:** Scale by running multiple instances of your process, not by making processes larger.

**Requirements:**
- Design processes to be stateless and independently scalable
- Different process types for different workloads (web, worker, cron)
- Use OS process manager (systemd, supervisor) or platform (Kubernetes, ECS)
- Horizontal scaling over vertical scaling

**Process Types:**
```bash
# Procfile (Heroku-style)
web: gunicorn app:app --workers 4
worker: celery -A tasks worker --loglevel=info
scheduler: celery -A tasks beat
```

**Implementation:**

```python
# Scale web processes horizontally
# Run 3 instances of web process
$ heroku ps:scale web=3

# Run 5 instances of worker process
$ heroku ps:scale worker=5
```

**Kubernetes:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3  # Scale web processes
  template:
    spec:
      containers:
      - name: web
        image: myapp:v1.2.3
        command: ["gunicorn", "app:app"]
```

**Benefits:**
- Linear scaling
- Granular resource allocation per process type
- Fault tolerance (process crashes don't bring down app)

**Anti-patterns:**
- ❌ Single monolithic process
- ❌ Vertical scaling only (bigger instances)
- ❌ Manual process management

---

## IX. Disposability

### Maximize robustness with fast startup and graceful shutdown

**Rule:** Processes are disposable—can be started or stopped instantly.

**Requirements:**
- **Fast startup:** Minimize initialization time
- **Graceful shutdown:** Handle SIGTERM to finish current work
- **Crash resilience:** Process crashes should not corrupt state
- **Idempotent operations:** Safe to restart anytime

**Implementation:**

**Graceful Shutdown:**
```python
import signal
import sys

def graceful_shutdown(signum, frame):
    print("Received SIGTERM, shutting down gracefully...")
    # Finish current requests
    # Close database connections
    # Flush logs
    sys.exit(0)

signal.signal(signal.SIGTERM, graceful_shutdown)
```

**Fast Startup:**
```python
# Bad: Heavy initialization on every startup
def start_app():
    load_entire_dataset_into_memory()  # Slow!
    connect_to_10_databases()
    app.run()

# Good: Lazy loading, minimal startup
def start_app():
    # Connect to databases on-demand
    # Load data as needed
    app.run()
```

**Worker Jobs:**
```python
# Make jobs idempotent and resumable
def process_order(order_id):
    order = db.get_order(order_id)
    if order.status == 'completed':
        return  # Already processed, safe to re-run

    # Process order...
    order.status = 'completed'
    db.save(order)
```

**Benefits:**
- Elastic scaling (quickly add/remove instances)
- Painless deployments
- Resilient to infrastructure failures

---

## X. Dev/Prod Parity

### Keep development, staging, and production as similar as possible

**Rule:** Minimize gaps between development and production environments.

**Three Gaps to Minimize:**

1. **Time Gap:** Deploy frequently (hours, not weeks)
2. **Personnel Gap:** Developers deploy their own code
3. **Tools Gap:** Use same backing services in dev and prod

**Requirements:**
- Use same database type in dev and prod (not SQLite in dev, Postgres in prod)
- Use Docker/containers to ensure environment consistency
- Automate deployments to reduce time gap
- Infrastructure as Code for reproducible environments

**Implementation:**

**Bad (dev/prod divergence):**
```
Development: SQLite, synchronous tasks, mock services
Production:  PostgreSQL, async queue, real services
```

**Good (dev/prod parity):**
```bash
# docker-compose.yml for local dev
version: '3'
services:
  web:
    build: .
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db/myapp
      REDIS_URL: redis://redis:6379
  db:
    image: postgres:15
  redis:
    image: redis:7

# Production uses same Postgres 15, Redis 7
```

**Infrastructure as Code:**
```bash
# Same Terraform code for all environments
terraform apply -var="environment=dev"
terraform apply -var="environment=staging"
terraform apply -var="environment=production"
```

**Benefits:**
- Reduce production bugs caused by environment differences
- Faster debugging ("works on my machine" eliminated)
- Continuous deployment confidence

**Anti-patterns:**
- ❌ SQLite in dev, MySQL in production
- ❌ Mock services in dev, real services in prod
- ❌ Manual setup of dev environments

---

## XI. Logs

### Treat logs as event streams

**Rule:** Apps should not manage log files. Write all logs to stdout/stderr as time-ordered event streams.

**Requirements:**
- Never write to log files directly
- No log rotation logic in app code
- Stream to stdout/stderr
- Let execution environment capture and route logs

**Implementation:**

**Application:**
```python
import sys
import json
from datetime import datetime

# Write structured JSON logs to stdout
def log(level, message, **kwargs):
    log_entry = {
        'timestamp': datetime.utcnow().isoformat(),
        'level': level,
        'message': message,
        **kwargs
    }
    print(json.dumps(log_entry), file=sys.stdout)

log('INFO', 'User login', user_id=12345, ip='192.168.1.1')
log('ERROR', 'Database connection failed', error='timeout')
```

**Environment Routing:**
```bash
# Development: View directly
python app.py

# Production: Route to log aggregation
# Docker: logs → Docker logging driver → CloudWatch
# Kubernetes: stdout → Fluentd → Elasticsearch
# Heroku: stdout → Logplex → Papertrail
```

**CloudWatch (AWS):**
```bash
# ECS automatically sends stdout/stderr to CloudWatch
# No application code needed
```

**Benefits:**
- Centralized log aggregation
- Search and analyze across all instances
- No disk space management needed
- Long-term archival to S3, Elasticsearch

**Anti-patterns:**
- ❌ `log_file = open('/var/log/app.log', 'a')`
- ❌ Custom log rotation in application
- ❌ Different log formats for different environments

---

## XII. Admin Processes

### Run admin/management tasks as one-off processes

**Rule:** Administrative tasks run as one-off processes in the same environment as the application.

**Admin Tasks:**
- Database migrations
- Console/REPL for inspection
- One-time scripts (data fixes, cleanup)
- Scheduled jobs (reports, cleanup)

**Requirements:**
- Run in same environment (same config, same codebase)
- Shipped with application code
- Use same dependency isolation
- Run against same release

**Implementation:**

**Database Migrations:**
```bash
# Run migration as one-off process
$ heroku run python manage.py migrate

# AWS ECS Task
$ aws ecs run-task --task-definition myapp-migration --cluster prod
```

**Django Management Commands:**
```python
# manage.py command shipped with code
# myapp/management/commands/cleanup_old_data.py
from django.core.management.base import BaseCommand

class Command(BaseCommand):
    def handle(self, *args, **options):
        # Cleanup logic
        pass

# Run as one-off process
$ python manage.py cleanup_old_data
```

**Console Access:**
```bash
# Python REPL with app context
$ heroku run python
>>> from myapp import db
>>> db.query(User).count()

# Rails console
$ heroku run rails console
```

**Scheduled Tasks:**
```bash
# Cron-style scheduler (Heroku Scheduler, AWS EventBridge)
# Runs one-off process on schedule
0 2 * * * python manage.py send_daily_report
```

**Benefits:**
- Admin code version-controlled with app
- Same environment guarantees
- Easier debugging and testing of admin tasks

**Anti-patterns:**
- ❌ SSH into production server to run scripts
- ❌ Admin tools with different dependencies
- ❌ Manual SQL run directly on database

---

## Twelve-Factor Compliance Checklist

Use this checklist to verify twelve-factor compliance:

- [ ] **Codebase:** Single repo, multiple deploys
- [ ] **Dependencies:** Explicit declaration (requirements.txt, package.json)
- [ ] **Config:** Environment variables, not code
- [ ] **Backing Services:** Accessed via URLs from config
- [ ] **Build/Release/Run:** Separate stages, immutable releases
- [ ] **Processes:** Stateless, shared-nothing
- [ ] **Port Binding:** Self-contained, exports via port
- [ ] **Concurrency:** Scale via process instances
- [ ] **Disposability:** Fast startup, graceful shutdown
- [ ] **Dev/Prod Parity:** Same backing services across environments
- [ ] **Logs:** Stdout/stderr, not log files
- [ ] **Admin Processes:** One-off tasks in same environment

---

## Cloud Platform Support

The twelve-factor methodology works seamlessly with:

- **Heroku:** Original platform, native twelve-factor support
- **AWS:** ECS, Elastic Beanstalk, App Runner, Lambda
- **Google Cloud:** Cloud Run, App Engine, GKE
- **Azure:** App Service, Container Instances, AKS
- **Platform-agnostic:** Docker + Kubernetes

---

## Extending Twelve-Factor for AI Systems

### Well-Architected AI Systems

Modern AI/ML applications should combine twelve-factor methodology with AWS Well-Architected Framework principles. AI systems have unique requirements around model lifecycle, data pipelines, and computational resources.

#### The Six Pillars for AI Workloads

**1. Operational Excellence**

Monitor model performance and implement automated retraining pipelines.

```python
# Monitor model drift
def monitor_model_performance():
    current_metrics = evaluate_model(production_data)
    if current_metrics['accuracy'] < ACCURACY_THRESHOLD:
        trigger_retraining_pipeline()
        log('WARNING', 'Model drift detected', metrics=current_metrics)

# Automated retraining pipeline (one-off process per Factor XII)
def retrain_model():
    """Run as scheduled admin process"""
    new_data = fetch_training_data()
    model = train_model(new_data)
    if validate_model(model):
        deploy_model(model)
```

**2. Security**

- Store model artifacts and training data securely
- Implement data privacy controls (anonymization, encryption)
- Use least-privilege access for ML pipelines
- Version and audit model deployments

```python
# Secure model configuration (Factor III: Config)
MODEL_BUCKET = os.environ['MODEL_ARTIFACTS_BUCKET']
TRAINING_DATA_URL = os.environ['TRAINING_DATA_URL']  # Encrypted S3 bucket

# Access control
def deploy_model(model_version):
    # Require explicit approval for production deployments
    if not has_approval(model_version):
        raise PermissionError("Model deployment requires approval")

    s3_client.upload_file(
        f'model-{model_version}.pkl',
        MODEL_BUCKET,
        ServerSideEncryption='AES256'
    )
```

**3. Reliability**

- Design for model failure with fallback strategies
- Implement circuit breakers for ML inference
- Use A/B testing for gradual rollouts
- Maintain model versioning and rollback capability

```python
# Reliable inference with fallback (Factor IX: Disposability)
def predict_with_fallback(input_data):
    try:
        # Try latest model
        return model_v2.predict(input_data)
    except Exception as e:
        log('ERROR', 'Model v2 failed, falling back to v1', error=str(e))
        # Fallback to previous stable version
        return model_v1.predict(input_data)

# Circuit breaker pattern
class ModelCircuitBreaker:
    def __init__(self, failure_threshold=5):
        self.failure_count = 0
        self.threshold = failure_threshold
        self.is_open = False

    def call(self, func, *args):
        if self.is_open:
            return self.fallback()

        try:
            result = func(*args)
            self.failure_count = 0
            return result
        except Exception:
            self.failure_count += 1
            if self.failure_count >= self.threshold:
                self.is_open = True
            return self.fallback()
```

**4. Performance Efficiency**

- Right-size compute for training vs inference
- Use model optimization techniques (quantization, pruning)
- Implement caching for repeated predictions
- Scale inference horizontally (Factor VIII: Concurrency)

```python
# Horizontal scaling for inference (Factor VIII)
# Deploy multiple stateless inference processes
# Procfile:
# inference: gunicorn inference_api:app --workers 8

# Model caching (Factor VI: Stateless processes with backing service)
import redis

class CachedPredictor:
    def __init__(self):
        self.redis = redis.from_url(os.environ['REDIS_URL'])
        self.model = load_model()

    def predict(self, input_hash, input_data):
        # Check cache first
        cached_result = self.redis.get(f'prediction:{input_hash}')
        if cached_result:
            return json.loads(cached_result)

        # Compute and cache
        result = self.model.predict(input_data)
        self.redis.setex(
            f'prediction:{input_hash}',
            3600,  # 1 hour TTL
            json.dumps(result)
        )
        return result
```

**5. Cost Optimization**

- Use spot instances for training jobs
- Implement auto-scaling for inference
- Optimize model size for deployment
- Monitor and analyze compute costs

```bash
# Spot instances for training (AWS Batch, SageMaker)
# Training jobs as one-off processes (Factor XII)
aws batch submit-job \
  --job-name model-training \
  --job-queue spot-queue \
  --job-definition training-job

# Auto-scaling inference (Factor VIII: Concurrency)
# Scale based on request load
aws application-autoscaling put-scaling-policy \
  --policy-name scale-inference \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10
```

**6. Sustainability**

- Optimize model efficiency (smaller models, fewer parameters)
- Use carbon-aware computing (schedule training in low-carbon regions)
- Implement model compression and efficient architectures
- Monitor energy consumption metrics

```python
# Efficient model serving
def optimize_for_sustainability():
    # Use quantized models for reduced compute
    model = load_quantized_model()  # 8-bit instead of 32-bit

    # Batch predictions for efficiency
    def batch_predict(inputs, batch_size=32):
        results = []
        for i in range(0, len(inputs), batch_size):
            batch = inputs[i:i + batch_size]
            results.extend(model.predict(batch))
        return results
```

#### AI-Specific Twelve-Factor Adaptations

**Data as a Dependency (extends Factor II)**

```python
# Declare data dependencies explicitly
# data-requirements.txt
"""
training-dataset==v2.3.0
validation-dataset==v2.3.0
feature-definitions==v1.5.0
"""

# Version data like code (Factor I: Codebase)
TRAINING_DATA_VERSION = os.environ['TRAINING_DATA_VERSION']
data_url = f's3://ml-data/training-{TRAINING_DATA_VERSION}.parquet'
```

**Model as Configuration (extends Factor III)**

```bash
# Model versions in environment
MODEL_VERSION=v2.5.3
MODEL_ARTIFACT_URL=s3://ml-models/production/model-v2.5.3.pkl
FEATURE_STORE_URL=https://features.example.com

# Swap models without code changes (Factor IV: Backing Services)
# Development: MODEL_VERSION=v2.5.3-dev
# Staging:     MODEL_VERSION=v2.5.3-rc1
# Production:  MODEL_VERSION=v2.5.3
```

**Stateless Inference (extends Factor VI)**

```python
# Never store prediction history in process memory
# Bad:
class StatefulPredictor:
    def __init__(self):
        self.prediction_history = []  # Anti-pattern!

# Good: Store in backing service
class StatelessPredictor:
    def __init__(self):
        self.model = load_model()
        self.db = connect_to_database(os.environ['DATABASE_URL'])

    def predict_and_store(self, input_data, user_id):
        prediction = self.model.predict(input_data)

        # Store in database, not in process
        self.db.predictions.insert({
            'user_id': user_id,
            'input': input_data,
            'output': prediction,
            'model_version': os.environ['MODEL_VERSION'],
            'timestamp': datetime.utcnow()
        })

        return prediction
```

**Build, Release, Run for ML (extends Factor V)**

```bash
# ML Pipeline Stages

# 1. BUILD: Train model
python train.py
python evaluate.py
python package_model.py  # Creates model artifact

# 2. RELEASE: Version and tag model
aws s3 cp model.pkl s3://models/model-v${VERSION}.pkl
echo "model-v${VERSION}" > CURRENT_VERSION

# 3. RUN: Deploy model to inference service
docker build -t inference:v${VERSION} .
docker run -e MODEL_VERSION=v${VERSION} inference:v${VERSION}

# Rollback capability
docker run -e MODEL_VERSION=v2.4.0 inference:v2.4.0  # Previous version
```

#### ML-Specific Logging (extends Factor XI)

```python
# Structured logging for ML systems
def log_prediction(input_data, prediction, model_version):
    log_entry = {
        'timestamp': datetime.utcnow().isoformat(),
        'event': 'prediction',
        'model_version': model_version,
        'input_hash': hash_input(input_data),
        'prediction': prediction,
        'latency_ms': get_latency(),
        'confidence': get_confidence_score(prediction)
    }
    # Logs to stdout (Factor XI)
    print(json.dumps(log_entry), file=sys.stdout)

# Monitor for model drift
def log_model_metrics():
    metrics = {
        'timestamp': datetime.utcnow().isoformat(),
        'event': 'model_metrics',
        'accuracy': current_accuracy,
        'precision': current_precision,
        'recall': current_recall,
        'data_drift': detect_drift_score()
    }
    print(json.dumps(metrics), file=sys.stdout)
```

#### Checklist: Twelve-Factor AI Systems

- [ ] **Versioned Data:** Training data in version control or versioned storage
- [ ] **Model Artifacts:** Stored as immutable releases with semantic versioning
- [ ] **Stateless Inference:** No prediction history in process memory
- [ ] **Environment-Based Config:** Model versions and endpoints in env vars
- [ ] **Horizontal Scaling:** Multiple inference processes behind load balancer
- [ ] **Monitoring:** Model performance metrics logged to stdout
- [ ] **Fallback Strategy:** Graceful degradation when model fails
- [ ] **A/B Testing:** Gradual rollout of new model versions
- [ ] **Automated Retraining:** Scheduled admin processes for model updates
- [ ] **Resource Right-Sizing:** Different compute for training vs inference

---

## Related Resources

- **Official 12-Factor Site:** https://12factor.net
- **Beyond the Twelve-Factor App:** https://www.oreilly.com/library/view/beyond-the-twelve-factor/9781492042631/
- **AWS Well-Architected Framework:** https://aws.amazon.com/architecture/well-architected/
- **AWS Well-Architected Machine Learning Lens:** https://docs.aws.amazon.com/wellarchitected/latest/machine-learning-lens/
- See `base/architecture-principles.md` for broader architectural guidance
- See `base/cicd-comprehensive.md` for deployment automation practices
- See `base/development-workflow.md` for day-to-day development practices
- See `cloud/aws/well-architected.md` for detailed AWS Well-Architected guidance
