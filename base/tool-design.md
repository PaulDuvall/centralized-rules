# Tool Design Best Practices

> **When to apply:** All CLI tools, developer tools, and automation scripts
> **Maturity Level:** All levels (good tool design scales from MVP to Production)

Design developer tools and CLIs that are intuitive, self-documenting, extensible, and composable.

## Overview

**Great tools are:**
- **Intuitive** - Work as expected without reading docs
- **Forgiving** - Prevent mistakes, easy to undo
- **Fast** - Respond instantly for common operations
- **Extensible** - Allow customization for advanced users
- **Composable** - Play well with other tools
- **Self-documenting** - Built-in help and examples

---

## Smart Defaults

### Convention Over Configuration

Users shouldn't configure what you can intelligently infer.

```python
# ❌ BAD: Require explicit configuration
@click.command()
@click.option('--input-file', required=True)
@click.option('--output-file', required=True)
@click.option('--format', required=True)
@click.option('--encoding', required=True)
def process(input_file, output_file, format, encoding):
    pass

# Usage requires 4 options
# $ tool process --input-file data.csv --output-file out.json --format json --encoding utf-8

# ✅ GOOD: Intelligent defaults
@click.command()
@click.argument('input_file')
@click.option('--output-file', default=None)
@click.option('--format', default=None)  # Auto-detect
@click.option('--encoding', default='utf-8')
def process(input_file, output_file, format, encoding):
    """Process a file with smart defaults"""

    if output_file is None:
        output_file = input_file.replace('.csv', '.json')

    if format is None:
        format = detect_format(output_file)

    do_process(input_file, output_file, format, encoding)

# Simple usage
# $ tool process data.csv
```

### Auto-Detection and Inference

Detect context automatically:

```python
def get_project_root() -> Path:
    """Auto-detect project root"""
    current = Path.cwd()
    markers = ['.git', 'package.json', 'pyproject.toml']

    while current != current.parent:
        for marker in markers:
            if (current / marker).exists():
                return current
        current = current.parent

    return Path.cwd()

def get_environment() -> str:
    """Auto-detect environment from context"""

    if env := os.getenv('ENVIRONMENT'):
        return env

    branch = get_current_git_branch()
    if branch == 'main':
        return 'production'
    elif branch == 'staging':
        return 'staging'
    else:
        return 'development'
```

### Progressive Disclosure

Simple by default, powerful when needed:

```bash
# Level 1: Simplest usage
$ deploy

# Level 2: Common customization
$ deploy --environment staging

# Level 3: Advanced options
$ deploy --environment staging --region us-west-2 --health-check-path /api/health

# Level 4: Full control
$ deploy --environment staging --region us-west-2 --timeout 300 --rollback-on-failure
```

---

## Self-Documenting Tools

### Built-in Help

Every command should explain itself:

```python
@click.group()
def cli():
    """
    MyTool - Developer productivity toolkit

    Common commands:
      deploy    Deploy application to environment
      logs      View application logs
      status    Check application health

    Examples:
      $ mytool deploy staging
      $ mytool logs --follow
    """
    pass

@cli.command()
@click.argument('environment', type=click.Choice(['dev', 'staging', 'production']))
@click.option('--dry-run', is_flag=True, help='Show what would be deployed')
def deploy(environment, dry_run):
    """
    Deploy application to specified environment.

    Examples:
      Deploy to staging:
        $ mytool deploy staging

      Dry run:
        $ mytool deploy production --dry-run

    Note:
      Production deployments require approval in #deployments Slack channel.
    """
    if dry_run:
        click.echo("Dry run mode - no changes will be made")

    click.echo(f"Deploying to {environment}...")
```

### Interactive Guidance

Help users when they make mistakes:

```python
@click.command()
@click.argument('service')
def logs(service):
    """View logs for a service"""

    available_services = get_available_services()

    if service not in available_services:
        click.echo(f"Service '{service}' not found.\n")
        click.echo("Available services:")
        for s in available_services:
            click.echo(f"  - {s}")
        click.echo(f"\nDid you mean: {suggest_similar(service, available_services)}?")
        raise click.Abort()

    stream_logs(service)

# Output:
# $ mytool logs api-sever
# Service 'api-sever' not found.
#
# Available services:
#   - api-server
#   - worker
#
# Did you mean: api-server?
```

---

## Extensibility Through Hooks

### Hook System Design

Allow users to customize behavior without modifying tool:

```python
class HookManager:
    """Manage and execute user-defined hooks"""

    def __init__(self, hooks_dir: Path):
        self.hooks_dir = hooks_dir
        self.hooks: Dict[str, List[Callable]] = {}

    def load_hooks(self):
        """Load hooks from hooks directory"""
        if not self.hooks_dir.exists():
            return

        for hook_file in self.hooks_dir.glob('*.py'):
            self._load_hook_file(hook_file)

    def register_hook(self, name: str, func: Callable):
        """Register a hook function"""
        if name not in self.hooks:
            self.hooks[name] = []
        self.hooks[name].append(func)

    def run_hooks(self, name: str, **kwargs):
        """Execute all hooks for an event"""
        if name not in self.hooks:
            return

        for hook in self.hooks[name]:
            try:
                hook(**kwargs)
            except Exception as e:
                print(f"Hook {name} failed: {e}")

# Usage in tool
hooks = HookManager(Path('.hooks'))
hooks.load_hooks()

def deploy(environment):
    """Deploy with hooks"""
    hooks.run_hooks('on_before_deploy', environment=environment)
    perform_deployment(environment)
    hooks.run_hooks('on_after_deploy', environment=environment)
```

**User-defined hook:**

```python
# .hooks/notifications.py

def on_before_deploy(environment, **kwargs):
    """Send Slack notification before deployment"""
    if environment == 'production':
        send_slack_message(
            channel='#deployments',
            message='Production deployment starting...'
        )

def on_after_deploy(environment, **kwargs):
    """Send Slack notification after deployment"""
    if environment == 'production':
        send_slack_message(
            channel='#deployments',
            message='Production deployment complete'
        )
```

### Configuration Hooks

```yaml
# .toolrc - User configuration with hooks

hooks:
  before_deploy:
    - run: npm run build
      on_error: abort
    - run: npm test
      on_error: abort

  after_deploy:
    - run: curl https://api.example.com/health
      timeout: 30
      on_error: rollback
```

---

## Modular Command Design

### Command Structure

Keep commands focused and composable:

```python
# ❌ BAD: Monolithic command
@click.command()
@click.option('--build', is_flag=True)
@click.option('--test', is_flag=True)
@click.option('--deploy', is_flag=True)
def do_everything(build, test, deploy):
    """Does everything - hard to use and maintain"""
    pass

# ✅ GOOD: Separate, composable commands
@click.group()
def cli():
    pass

@cli.command()
def build():
    """Build the application"""
    run_build()

@cli.command()
def test():
    """Run tests"""
    run_tests()

@cli.command()
@click.argument('environment')
def deploy(environment):
    """Deploy to environment"""
    run_deployment(environment)

# Composable in scripts:
# $ mytool build && mytool test && mytool deploy staging
```

---

## Tool Composability

### Unix Philosophy

Write tools that do one thing well and compose with others:

```bash
# Good tools work with pipes

# Count errors in logs
$ mytool logs api-server | grep ERROR | wc -l

# Get top 10 error types
$ mytool logs api-server | grep ERROR | sort | uniq -c | sort -rn | head -10

# Chain with other tools
$ mytool search "status:active" --format json | jq '.[] | .email'
```

### Structured Output

Support multiple output formats:

```python
@click.command()
@click.argument('resource')
@click.option('--format', type=click.Choice(['table', 'json', 'csv']), default='table')
@click.option('--output', type=click.File('w'), default='-')
def list(resource, format, output):
    """List resources in various formats"""

    data = fetch_data(resource)

    if format == 'json':
        json.dump(data, output, indent=2)
    elif format == 'csv':
        writer = csv.DictWriter(output, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)
    elif format == 'table':
        print_table(data, output)

# Usage:
# $ mytool list users --format json > users.json
# $ mytool list users --format csv | column -t -s,
# $ mytool list users --format json | jq '.[] | select(.role=="admin")'
```

---

## Error Handling and User Experience

### Helpful Error Messages

```python
# ❌ BAD: Cryptic errors
def deploy(version):
    try:
        do_deploy(version)
    except Exception as e:
        click.echo(f"Error: {e}")
        sys.exit(1)

# ✅ GOOD: Helpful errors with context
def deploy(version):
    try:
        do_deploy(version)

    except VersionNotFound:
        click.echo(f"Version '{version}' not found.\n")
        available = get_available_versions()
        click.echo("Available versions:")
        for v in available[-5:]:
            click.echo(f"  - {v}")
        click.echo("\nTo see all versions: mytool list-versions")
        sys.exit(1)

    except PermissionDenied:
        click.echo("You don't have permission to deploy to production.\n")
        click.echo("Request access: https://access.example.com")
        sys.exit(1)

    except NetworkError as e:
        click.echo(f"Network error during deployment.\n")
        click.echo(f"Error: {e}\n")
        click.echo("Possible solutions:")
        click.echo("  - Check your internet connection")
        click.echo("  - Verify VPN is connected")
        sys.exit(1)
```

### Progress Feedback

```python
def deploy_with_progress(environment):
    """Deploy with progress indicators"""

    steps = [
        ("Building application", build_app),
        ("Running tests", run_tests),
        ("Deploying to cluster", deploy_to_cluster),
        ("Running health checks", health_check),
    ]

    with click.progressbar(
        steps,
        label='Deploying to production',
        item_show_func=lambda x: x[0] if x else ''
    ) as bar:
        for step_name, step_func in bar:
            step_func()
```

---

## Related Resources

- See `base/ai-assisted-development.md` for AI tool integration
- See `base/operations-automation.md` for automation best practices
- See `base/development-workflow.md` for developer experience
- See `base/cicd-comprehensive.md` for CI/CD tooling

---

**Remember:** Great tools are invisible—users accomplish their goals without thinking about the tool. Invest in smart defaults, clear documentation, and excellent error messages.
