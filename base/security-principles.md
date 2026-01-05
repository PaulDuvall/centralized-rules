# Security Principles
<!-- TIP: Security isn't optional - validate all inputs -->

> **Scope:** All code across any language or framework

## Maturity Requirements

| Practice | MVP/POC | Pre-Production | Production |
|----------|---------|----------------|------------|
| No hardcoded secrets | Required | Required | Required |
| Input validation | Recommended | Required | Required |
| Authentication | Optional | Required | Required |
| Authorization (RBAC) | Optional | Recommended | Required |
| Security headers | Optional | Recommended | Required |
| HTTPS enforcement | Optional | Required | Required |
| Rate limiting | Not needed | Recommended | Required |
| Security scanning (SAST) | Not needed | Recommended | Required |
| Dependency vulnerability scanning | Optional | Required | Required |
| Secret scanning (git-secrets) | Optional | Required | Required |
| Penetration testing | Not needed | Optional | Recommended |

## Core Security Principles

### 1. Never Hardcode Secrets
**CRITICAL:** Never commit secrets, API keys, passwords, or tokens to source control.

- Use environment variables for all secrets
- Use `.env` files for local development (gitignore them)
- Use secret management services (AWS Secrets Manager, Vault)
- Document required environment variables

```
❌ API_KEY = 'sk-1234567890abcdef'

✅ API_KEY = os.getenv('API_KEY')
   if not API_KEY:
       raise ValueError('API_KEY not set')
```

### 2. Input Validation
**MANDATORY:** Validate and sanitize all external input at system boundaries.

**Validate:**
- User-provided data
- File uploads and paths
- URL parameters
- Form submissions
- API requests
- Configuration files

**How:**
- Use allowlists, not blocklists
- Validate data types and formats
- Check length and range constraints
- Sanitize before processing
- Prevent path traversal attacks

### 3. Authentication & Authorization

**Authentication:**
- Use established libraries (never roll your own crypto)
- Hash passwords with bcrypt, Argon2, or scrypt
- Implement account lockout after failed attempts
- Use secure session management
- Support multi-factor authentication

**Authorization:**
- Implement role-based access control (RBAC)
- Apply principle of least privilege
- Check permissions on every protected operation
- Validate authorization server-side only

### 4. Secure Data Storage

- Encrypt sensitive data at rest
- Use parameterized queries (prevent SQL injection)
- Never store plaintext passwords
- Use secure hashing algorithms
- Protect database credentials

### 5. Secure Communication

- Use HTTPS/TLS for all network communication
- Validate SSL certificates
- Don't transmit secrets in URLs
- Implement proper CORS policies
- Use secure protocols only (no HTTP, FTP, Telnet)

### 6. Error Handling & Logging

**Error Messages:**
- Don't expose internal details
- Return generic messages to users
- Log detailed errors server-side

```
❌ "Database connection failed at server 10.0.0.5:5432 with user admin_user"
✅ "Service temporarily unavailable"
```

**Logging:**
- Log security events (failed logins, access violations)
- Don't log secrets or sensitive data
- Use structured logging with correlation IDs
- Protect log integrity

### 7. Dependency Management

- Keep dependencies up to date
- Scan for known vulnerabilities regularly
- Use dependency lock files
- Only use trusted packages
- Remove unused dependencies
- Monitor security advisories

### 8. Principle of Least Privilege

- Grant minimum necessary permissions
- Don't run services as root/admin
- Use separate credentials per environment
- Implement RBAC
- Regularly review and revoke access

### 9. Secure Defaults

- Default to secure configurations
- Disable unnecessary features
- Require explicit opt-in for insecure options
- Document security implications

### 10. Security Testing

- Include security tests in test suite
- Test authentication and authorization
- Test input validation with malicious inputs
- Perform regular security scans
- Test error handling doesn't leak information
- Consider penetration testing for critical systems

## Common Vulnerabilities & Prevention

### Injection Attacks
- Use parameterized queries/prepared statements
- Validate and sanitize all input
- Use ORMs that handle escaping
- Never concatenate user input into commands

### Cross-Site Scripting (XSS)
- Escape output based on context
- Use Content Security Policy (CSP) headers
- Sanitize user input
- Use framework built-in protections

### Cross-Site Request Forgery (CSRF)
- Use CSRF tokens
- Verify origin headers
- Use SameSite cookie attribute
- Require re-authentication for sensitive operations

### Broken Authentication
- Use established authentication libraries
- Implement multi-factor authentication
- Use secure session management
- Implement account lockout
- Hash passwords properly

### Sensitive Data Exposure
- Encrypt data at rest and in transit
- Don't store unnecessary sensitive data
- Use HTTPS everywhere
- Implement proper key management
- Disable autocomplete on sensitive fields

### Security Misconfiguration
- Remove default accounts and credentials
- Disable unnecessary features and services
- Keep software up to date
- Implement security headers (CSP, HSTS, X-Frame-Options)
- Regular security configuration reviews

### Vulnerable Dependencies
- Regular dependency updates
- Automated vulnerability scanning
- Monitor security advisories
- Have update/patch process
- Remove unused dependencies

### Insufficient Logging & Monitoring
- Log security-relevant events
- Monitor for suspicious activity
- Implement alerting
- Protect log integrity
- Regular log review

## Secure Development Checklist

Before deploying code:

- [ ] No hardcoded secrets or credentials
- [ ] All user input validated and sanitized
- [ ] Authentication and authorization implemented
- [ ] Sensitive data encrypted
- [ ] HTTPS used for all communication
- [ ] Error messages don't leak information
- [ ] Dependencies scanned for vulnerabilities
- [ ] Security tests passing
- [ ] Security events logged (without secrets)
- [ ] Principle of least privilege applied
- [ ] Security headers configured
- [ ] Rate limiting implemented

## Development Workflow

1. **Design** - Consider security from start
2. **Code** - Follow secure coding practices
3. **Review** - Include security in code reviews
4. **Test** - Write security tests
5. **Scan** - Run security scanners (SAST, dependency)
6. **Fix** - Address vulnerabilities before deployment
7. **Monitor** - Track security events in production

## Incident Response

If security issue discovered:

1. **Assess** - Determine scope and impact
2. **Contain** - Prevent further damage
3. **Fix** - Develop and test patch
4. **Deploy** - Roll out fix urgently
5. **Notify** - Inform affected users if required
6. **Learn** - Document and prevent recurrence

**Severity levels:**
- **Critical** - Active exploitation or data breach (fix immediately)
- **High** - Serious vulnerability (fix within days)
- **Medium** - Important issue (fix in next release)
- **Low** - Minor issue (fix when convenient)

## Security Resources

- OWASP Top 10 - Most critical security risks
- CWE Top 25 - Most dangerous software weaknesses
- NIST guidelines - Security standards
- Framework-specific security guides

## Remember

- **Security is not optional** - Build it in from start
- **Assume breach mentality** - Plan for when attacks occur
- **Defense in depth** - Multiple layers of security
- **Keep it simple** - Complex security is hard to maintain
- **Stay updated** - Security landscape constantly evolves
