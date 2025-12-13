# Security Principles

> **When to apply:** All code across any language or framework

## Core Security Principles

### 1. Never Hardcode Secrets

**CRITICAL:** Never commit secrets, API keys, passwords, or tokens to source control.

- Use environment variables for all secrets
- Never hardcode credentials in code
- Use `.env` files for local development (and gitignore them)
- Document required environment variables
- Use secret management services for production

**Why:** Hardcoded secrets can be exposed in version control and create security vulnerabilities.

**Example Pattern:**
```
❌ Bad: Hardcoded secret
API_KEY = 'sk-1234567890abcdef'

✅ Good: Environment variable
API_KEY = environment.get('API_KEY')
if not API_KEY:
    error('API_KEY not set | Add to .env or set environment variable')
```

### 2. Input Validation

**MANDATORY:** Validate and sanitize all user input.

- Validate all external input at system boundaries
- Use allowlists (not blocklists) when possible
- Sanitize data before processing
- Validate file paths to prevent traversal attacks
- Check data types and formats

**Why:** Unvalidated input is the root cause of many security vulnerabilities (injection attacks, XSS, etc.).

**What to Validate:**
- User-provided data
- File uploads
- URL parameters
- Form submissions
- API requests
- Configuration files

### 3. Secure Authentication & Authorization

- Implement proper authentication for all protected resources
- Use established authentication libraries/frameworks
- Never roll your own crypto
- Implement proper authorization checks
- Follow principle of least privilege
- Use secure session management

**Why:** Authentication and authorization bugs lead to unauthorized access.

### 4. Secure Data Storage

- Encrypt sensitive data at rest
- Use strong encryption algorithms
- Never store plaintext passwords
- Use secure hashing for passwords (bcrypt, Argon2, etc.)
- Protect database credentials
- Use parameterized queries to prevent SQL injection

**Why:** Data breaches expose user information and damage trust.

### 5. Secure Communication

- Use HTTPS/TLS for all network communication
- Validate SSL certificates
- Don't transmit secrets in URLs
- Use secure protocols (avoid HTTP, FTP, Telnet)
- Implement proper CORS policies

**Why:** Unencrypted communication can be intercepted.

### 6. Error Handling & Logging

- Don't expose sensitive information in error messages
- Log security events (failed logins, access violations)
- Don't log secrets or sensitive data
- Implement proper error handling
- Use structured logging with correlation IDs

**Why:** Error messages can leak information to attackers.

**Example:**
```
❌ Bad: Exposes internal details
Error: Database connection failed at server 10.0.0.5:5432 with user admin_user

✅ Good: Generic error message
Error: Service temporarily unavailable | Check logs for details
```

### 7. Dependency Management

- Keep dependencies up to date
- Scan for known vulnerabilities
- Use dependency lock files
- Only use trusted packages/libraries
- Regularly audit dependencies
- Remove unused dependencies

**Why:** Vulnerable dependencies are a common attack vector.

### 8. Principle of Least Privilege

- Grant minimum necessary permissions
- Don't run services as root/admin
- Use separate credentials for different environments
- Implement role-based access control (RBAC)
- Regularly review and revoke unnecessary access

**Why:** Limiting privileges reduces the impact of compromises.

### 9. Secure Defaults

- Default to secure configurations
- Disable unnecessary features
- Use secure defaults for libraries and frameworks
- Require explicit opt-in for insecure options
- Document security implications of configuration changes

**Why:** Many vulnerabilities come from insecure default configurations.

### 10. Security Testing

- Include security tests in test suite
- Test authentication and authorization
- Test input validation
- Perform regular security scans
- Consider penetration testing for critical systems
- Test error handling doesn't leak information

**Why:** Security bugs should be caught before production.

## Common Security Vulnerabilities

### Injection Attacks

**Problem:** Untrusted data sent to interpreter as part of command or query

**Prevention:**
- Use parameterized queries/prepared statements
- Validate and sanitize all input
- Use ORMs that handle escaping
- Never concatenate user input into commands

### Cross-Site Scripting (XSS)

**Problem:** Malicious scripts injected into web pages

**Prevention:**
- Escape output based on context (HTML, JavaScript, URL)
- Use Content Security Policy (CSP)
- Sanitize user input
- Use framework built-in protections

### Cross-Site Request Forgery (CSRF)

**Problem:** Unauthorized commands transmitted from trusted user

**Prevention:**
- Use CSRF tokens
- Verify origin headers
- Use SameSite cookie attribute
- Require re-authentication for sensitive operations

### Broken Authentication

**Problem:** Authentication implementation flaws

**Prevention:**
- Use established authentication libraries
- Implement multi-factor authentication
- Use secure session management
- Implement account lockout
- Hash passwords properly

### Sensitive Data Exposure

**Problem:** Inadequate protection of sensitive information

**Prevention:**
- Encrypt sensitive data at rest and in transit
- Don't store unnecessary sensitive data
- Use HTTPS everywhere
- Implement proper key management
- Disable autocomplete on sensitive fields

### Security Misconfiguration

**Problem:** Insecure default configurations or incomplete setup

**Prevention:**
- Remove default accounts and credentials
- Disable unnecessary features and services
- Keep software up to date
- Implement security headers
- Regular security reviews

### Using Components with Known Vulnerabilities

**Problem:** Using libraries/frameworks with known security issues

**Prevention:**
- Regular dependency updates
- Automated vulnerability scanning
- Monitor security advisories
- Have update/patch process
- Remove unused dependencies

### Insufficient Logging & Monitoring

**Problem:** Lack of visibility into security events

**Prevention:**
- Log security-relevant events
- Monitor for suspicious activity
- Implement alerting
- Protect log integrity
- Regular log review

## Secure Development Checklist

Before deploying code, verify:

- [ ] No hardcoded secrets or credentials
- [ ] All user input validated and sanitized
- [ ] Authentication and authorization implemented properly
- [ ] Sensitive data encrypted
- [ ] HTTPS used for all communication
- [ ] Error messages don't leak sensitive information
- [ ] Dependencies scanned for vulnerabilities
- [ ] Security tests included and passing
- [ ] Logging includes security events (without secrets)
- [ ] Principle of least privilege applied

## Security in Development Workflow

### During Implementation:

1. **Design** - Consider security from the start
2. **Code** - Follow secure coding practices
3. **Review** - Include security in code reviews
4. **Test** - Write security tests
5. **Scan** - Run security scanners
6. **Fix** - Address vulnerabilities before deployment
7. **Monitor** - Track security events in production

### Security Testing Types:

- **Static Analysis** - Scan code for vulnerabilities
- **Dependency Scanning** - Check for known vulnerabilities
- **Dynamic Testing** - Test running application
- **Penetration Testing** - Simulate attacks
- **Security Reviews** - Manual code review for security

## Incident Response

### If Security Issue Discovered:

1. **Assess** - Determine scope and impact
2. **Contain** - Prevent further damage
3. **Fix** - Develop and test patch
4. **Deploy** - Roll out fix urgently
5. **Notify** - Inform affected users if required
6. **Learn** - Document and prevent recurrence

### Security Issue Priorities:

- **Critical** - Active exploitation or data breach (fix immediately)
- **High** - Serious vulnerability (fix within days)
- **Medium** - Important issue (fix in next release)
- **Low** - Minor issue (fix when convenient)

## Security Resources

### General Resources:
- OWASP Top 10 - Most critical security risks
- CWE Top 25 - Most dangerous software weaknesses
- NIST guidelines - Security standards and best practices

### Language/Framework-Specific:
- Refer to security guides for your specific tech stack
- Follow framework security best practices
- Use recommended security libraries

## Why Security Matters

### Impact of Security Failures:
- **Data Breaches** - Loss of sensitive information
- **Financial Loss** - Direct costs and fines
- **Reputation Damage** - Loss of user trust
- **Legal Liability** - Regulatory penalties
- **Business Disruption** - Downtime and recovery costs

### Benefits of Security First:
- **User Trust** - Customers feel safe
- **Compliance** - Meet regulatory requirements
- **Cost Savings** - Cheaper to prevent than fix breaches
- **Competitive Advantage** - Security as differentiator
- **Peace of Mind** - Sleep better at night

## Remember

- **Security is not optional** - It must be built in from the start
- **Assume breach mentality** - Plan for when (not if) attacks occur
- **Defense in depth** - Multiple layers of security
- **Keep it simple** - Complex security is hard to maintain
- **Stay updated** - Security landscape constantly evolves
