# Tool Design Best Practices

> **When to apply:** All CLI tools, developer tools, and automation scripts
> **Maturity Level:** All levels (good tool design scales from MVP to Production)

Design developer tools and CLIs that are intuitive, self-documenting, extensible, and composable through smart defaults, hooks, and modular architecture.

## Table of Contents

- [Overview](#overview)
- [Smart Defaults](#smart-defaults)
- [Self-Documenting Tools](#self-documenting-tools)
- [Extensibility Through Hooks](#extensibility-through-hooks)
- [Modular Command Design](#modular-command-design)
- [Tool Composability](#tool-composability)
- [Error Handling and User Experience](#error-handling-and-user-experience)

---

## Overview

### What Makes a Great Developer Tool?

**Great tools are:**
- **Intuitive** - Work as expected without reading docs
- **Forgiving** - Prevent mistakes, easy to undo
- **Fast** - Respond instantly for common operations
- **Extensible** - Allow customization for advanced users
- **Composable** - Play well with other tools
- **Self-documenting** - Built-in help and examples

**Poor tools are:**
- Require memorizing obscure flags
- Fail cryptically without helpful errors
- Inconsistent behavior across commands
- No way to customize or extend
- Cannot be scripted or automated

---

## Smart Defaults

### Principle: Convention Over Configuration

**Users shouldn't configure what you can intelligently infer.**

**Examples of Smart Defaults:**

```python
# ❌ BAD: Require explicit configuration

import click

@click.command()
@click.option('--input-file', required=True)
@click.option('--output-file', required=True)
@click.option('--format', required=True)
@click.option('--encoding', required=True)
@click.option('--compression', required=True)
def process(input_file, output_file, format, encoding, compression):
    """Process a file"""
    # User must specify everything!
    pass

# Usage requires 5 options:
# $ tool process --input-file data.csv --output-file out.json --format json --encoding utf-8 --compression gzip

# ✅ GOOD: Intelligent defaults

@click.command()
@click.argument('input_file')
@click.option('--output-file', default=None)  # Auto-generate from input
@click.option('--format', default=None)  # Auto-detect from extension
@click.option('--encoding', default='utf-8')
@click.option('--compression', default='auto')  # Auto-detect
def process(input_file, output_file, format, encoding, compression):
    """Process a file with smart defaults"""

    # Smart defaults
    if output_file is None:
        output_file = input_file.replace('.csv', '.json')

    if format is None:
        format = detect_format(output_file)

    if compression == 'auto':
        compression = 'gzip' if output_file.endswith('.gz') else None

    # Now process with inferred values
    do_process(input_file, output_file, format, encoding, compression)

# Simple usage:
# $ tool process data.csv
# Automatically creates data.json
```

### Auto-Detection and Inference

**Detect context automatically:**

```python
import os
from pathlib import Path

def get_project_root() -> Path:
    """Auto-detect project root"""
    current = Path.cwd()

    # Look for markers
    markers = ['.git', 'package.json', 'pyproject.toml', 'Cargo.toml']

    while current != current.parent:
        for marker in markers:
            if (current / marker).exists():
                return current
        current = current.parent

    # Default to current directory
    return Path.cwd()

def get_environment() -> str:
    """Auto-detect environment from context"""

    # Check environment variable first
    if env := os.getenv('ENVIRONMENT'):
        return env

    # Check git branch
    branch = get_current_git_branch()
    if branch == 'main':
        return 'production'
    elif branch == 'staging':
        return 'staging'
    else:
        return 'development'

def get_config_file() -> Path:
    """Auto-locate configuration file"""
    project_root = get_project_root()

    # Check standard locations
    config_locations = [
        project_root / '.toolrc',
        project_root / 'tool.config.json',
        Path.home() / '.config' / 'tool' / 'config.json',
    ]

    for location in config_locations:
        if location.exists():
            return location

    # Use default config
    return project_root / '.toolrc'
```

### Progressive Disclosure

**Simple by default, powerful when needed:**

```python
# Level 1: Simplest usage (smart defaults)
# $ deploy

# Level 2: Common customization
# $ deploy --environment staging

# Level 3: Advanced options
# $ deploy --environment staging --region us-west-2 --health-check-path /api/health

# Level 4: Full control
# $ deploy --environment staging --region us-west-2 --health-check-path /api/health \
#   --timeout 300 --rollback-on-failure --canary-percentage 10
```

---

## Self-Documenting Tools

### Built-in Help

**Every command should explain itself:**

```python
import click

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
      $ mytool status --all-services
    """
    pass

@cli.command()
@click.argument('environment', type=click.Choice(['dev', 'staging', 'production']))
@click.option('--dry-run', is_flag=True, help='Show what would be deployed without deploying')
@click.option('--force', is_flag=True, help='Skip confirmation prompts')
def deploy(environment, dry_run, force):
    """
    Deploy application to specified environment.

    ENVIRONMENT: Target environment (dev, staging, production)

    Examples:
      Deploy to staging:
        $ mytool deploy staging

      Dry run (see what would happen):
        $ mytool deploy production --dry-run

      Force deploy (skip confirmations):
        $ mytool deploy production --force

    Note:
      Production deployments require approval in #deployments Slack channel.
    """
    if dry_run:
        click.echo("Dry run mode - no changes will be made")

    click.echo(f"Deploying to {environment}...")
```

**Help output:**

```bash
$ mytool --help
Usage: mytool [OPTIONS] COMMAND [ARGS]...

  MyTool - Developer productivity toolkit

  Common commands:
    deploy    Deploy application to environment
    logs      View application logs
    status    Check application health

$ mytool deploy --help
Usage: mytool deploy [OPTIONS] ENVIRONMENT

  Deploy application to specified environment.

  Examples:
    Deploy to staging:
      $ mytool deploy staging

    Dry run (see what would happen):
      $ mytool deploy production --dry-run
```

### Interactive Guidance

**Help users when they make mistakes:**

```python
@click.command()
@click.argument('service')
def logs(service):
    """View logs for a service"""

    available_services = get_available_services()

    if service not in available_services:
        click.echo(f"❌ Service '{service}' not found.\n")
        click.echo("Available services:")
        for s in available_services:
            click.echo(f"  - {s}")
        click.echo(f"\nDid you mean: {suggest_similar(service, available_services)}?")
        raise click.Abort()

    stream_logs(service)

# Output:
# $ mytool logs api-sever
# ❌ Service 'api-sever' not found.
#
# Available services:
#   - api-server
#   - worker
#   - scheduler
#
# Did you mean: api-server?
```

### Examples in Help Text

```python
@click.command()
@click.argument('query')
@click.option('--format', type=click.Choice(['json', 'table', 'csv']), default='table')
@click.option('--limit', type=int, default=10)
def search(query, format, limit):
    """
    Search for resources.

    Examples:

      Search for users:
        $ mytool search "email:john@example.com"

      Get results as JSON:
        $ mytool search "role:admin" --format json

      Limit results:
        $ mytool search "created:today" --limit 5

      Pipe to other tools:
        $ mytool search "status:active" --format csv | grep "premium"

    Query syntax:
      field:value       Exact match
      field:*value*     Contains
      field:>100        Greater than
      field:<100        Less than
    """
    results = perform_search(query, limit)
    display_results(results, format)
```

---

## Extensibility Through Hooks

### Hook System Design

**Allow users to customize behavior without modifying tool:**

```python
# hooks.py

from pathlib import Path
from typing import Callable, Dict, List
import importlib.util

class HookManager:
    """Manage and execute user-defined hooks"""

    def __init__(self, hooks_dir: Path):
        self.hooks_dir = hooks_dir
        self.hooks: Dict[str, List[Callable]] = {}

    def load_hooks(self):
        """Load hooks from hooks directory"""
        if not self.hooks_dir.exists():
            return

        # Load Python files from hooks directory
        for hook_file in self.hooks_dir.glob('*.py'):
            self._load_hook_file(hook_file)

    def _load_hook_file(self, file_path: Path):
        """Load hooks from a Python file"""
        spec = importlib.util.spec_from_file_location("hook_module", file_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        # Register hooks from module
        for attr_name in dir(module):
            if attr_name.startswith('on_'):
                hook_name = attr_name
                hook_func = getattr(module, attr_name)
                self.register_hook(hook_name, hook_func)

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

# Hook events
hooks = HookManager(Path('.hooks'))
hooks.load_hooks()

# Usage in tool
def deploy(environment):
    """Deploy with hooks"""

    # Pre-deployment hook
    hooks.run_hooks('on_before_deploy', environment=environment)

    # Deployment
    perform_deployment(environment)

    # Post-deployment hook
    hooks.run_hooks('on_after_deploy', environment=environment)
```

**User-defined hook example:**

```python
# .hooks/notifications.py

def on_before_deploy(environment, **kwargs):
    """Send Slack notification before deployment"""
    if environment == 'production':
        send_slack_message(
            channel='#deployments',
            message=f'🚀 Production deployment starting...'
        )

def on_after_deploy(environment, **kwargs):
    """Send Slack notification after deployment"""
    if environment == 'production':
        send_slack_message(
            channel='#deployments',
            message=f'✅ Production deployment complete'
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

    - script: .hooks/notify-team.sh
      on_error: warn

  after_deploy:
    - run: curl https://api.example.com/health
      timeout: 30
      on_error: rollback

    - script: .hooks/update-changelog.sh
```

---

## Modular Command Design

### Command Structure

**Keep commands focused and composable:**

```python
# ❌ BAD: Monolithic command that does too much

@click.command()
@click.option('--build', is_flag=True)
@click.option('--test', is_flag=True)
@click.option('--deploy', is_flag=True)
@click.option('--notify', is_flag=True)
def do_everything(build, test, deploy, notify):
    """Does everything - hard to use and maintain"""
    if build:
        # Build logic
        pass
    if test:
        # Test logic
        pass
    if deploy:
        # Deploy logic
        pass
    if notify:
        # Notify logic
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

@cli.command()
@click.argument('message')
def notify(message):
    """Send notification"""
    send_notification(message)

# Composable in scripts:
# $ mytool build && mytool test && mytool deploy staging && mytool notify "Deployed to staging"
```

### Plugin Architecture

```python
# plugin_system.py

from pathlib import Path
from typing import Dict, Type
import importlib

class Plugin:
    """Base plugin class"""
    name: str = None

    def setup(self, app):
        """Initialize plugin"""
        pass

    def commands(self):
        """Return Click commands to register"""
        return []

class PluginManager:
    """Manage plugins"""

    def __init__(self):
        self.plugins: Dict[str, Plugin] = {}

    def load_plugins(self, plugins_dir: Path):
        """Load plugins from directory"""
        for plugin_file in plugins_dir.glob('*.py'):
            plugin = self._load_plugin(plugin_file)
            if plugin:
                self.plugins[plugin.name] = plugin

    def _load_plugin(self, file_path: Path) -> Plugin:
        """Load single plugin file"""
        # Import module and instantiate plugin class
        # (Implementation details omitted for brevity)
        pass

    def register_commands(self, cli_group):
        """Register all plugin commands"""
        for plugin in self.plugins.values():
            for command in plugin.commands():
                cli_group.add_command(command)

# Example plugin
# plugins/aws.py

class AWSPlugin(Plugin):
    name = "aws"

    def commands(self):
        @click.group()
        def aws():
            """AWS commands"""
            pass

        @aws.command()
        def list_instances():
            """List EC2 instances"""
            # Implementation
            pass

        return [aws]
```

---

## Tool Composability

### Unix Philosophy

**Write tools that do one thing well and compose with others:**

```bash
# Good tools work with pipes

# Count errors in logs
$ mytool logs api-server | grep ERROR | wc -l

# Get top 10 error types
$ mytool logs api-server | grep ERROR | sort | uniq -c | sort -rn | head -10

# Export data and process
$ mytool export users --format csv | awk -F',' '{print $2}' | sort

# Chain with other tools
$ mytool search "status:active" --format json | jq '.[] | .email' | mail -s "Active users"
```

### Structured Output

**Support multiple output formats:**

```python
import json
import csv
from typing import List, Dict

@click.command()
@click.argument('resource')
@click.option('--format', type=click.Choice(['table', 'json', 'csv', 'yaml']), default='table')
@click.option('--output', type=click.File('w'), default='-')  # - means stdout
def list(resource, format, output):
    """List resources in various formats"""

    data = fetch_data(resource)

    if format == 'json':
        json.dump(data, output, indent=2)

    elif format == 'csv':
        if not data:
            return
        writer = csv.DictWriter(output, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)

    elif format == 'yaml':
        import yaml
        yaml.dump(data, output)

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
        click.echo(f"Error: {e}")  # Unhelpful!
        sys.exit(1)

# ✅ GOOD: Helpful errors with context

def deploy(version):
    try:
        do_deploy(version)

    except VersionNotFound as e:
        click.echo(f"❌ Version '{version}' not found.\n")
        available = get_available_versions()
        click.echo(f"Available versions:")
        for v in available[-5:]:  # Show last 5
            click.echo(f"  - {v}")
        click.echo(f"\nTo see all versions: mytool list-versions")
        sys.exit(1)

    except PermissionDenied:
        click.echo(f"❌ You don't have permission to deploy to production.\n")
        click.echo(f"Request access: https://access.example.com")
        click.echo(f"Or contact your team lead.")
        sys.exit(1)

    except NetworkError as e:
        click.echo(f"❌ Network error during deployment.\n")
        click.echo(f"Error: {e}\n")
        click.echo(f"Possible solutions:")
        click.echo(f"  - Check your internet connection")
        click.echo(f"  - Verify VPN is connected")
        click.echo(f"  - Check firewall settings")
        sys.exit(1)
```

### Progress Feedback

```python
import click

def deploy_with_progress(environment):
    """Deploy with progress indicators"""

    steps = [
        ("Building application", build_app),
        ("Running tests", run_tests),
        ("Pushing to registry", push_to_registry),
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

# Or for long-running tasks:
def process_large_file(file_path):
    """Process file with progress bar"""

    with open(file_path) as f:
        lines = f.readlines()

    with click.progressbar(
        lines,
        label='Processing',
        show_eta=True,
        show_percent=True
    ) as bar:
        for line in bar:
            process_line(line)

    click.echo("✅ Processing complete")
```

---

## Related Resources

- See `base/ai-assisted-development.md` for AI tool integration
- See `base/operations-automation.md` for automation best practices
- See `base/development-workflow.md` for developer experience
- See `base/cicd-comprehensive.md` for CI/CD tooling

---

**Remember:** Great tools are invisible—users accomplish their goals without thinking about the tool. Invest in smart defaults, clear documentation, and excellent error messages to create tools developers love to use.
