# Playwright E2E Testing Rules

> Inspired by [OlenaRudovol/playwright-e2e-guidelines](https://github.com/OlenaRudovol/playwright-e2e-guidelines) (MIT License).
> Adapted for AI-native development workflows with CLAUDE.md integration.

## Meta

- **id**: playwright-e2e
- **version**: 1.0.0
- **scope**: `**/*.spec.ts`, `**/*.page.ts`, `**/fixtures/**`, `playwright.config.ts`
- **severity-levels**: `error` (blocks merge), `warn` (review required), `info` (recommendation)

---

## Section 1: Configuration (playwright.config.ts)

### RULE-PW-001: Base Configuration [error]

Every project must define these in `playwright.config.ts`:

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? '50%' : undefined,
  reporter: process.env.CI
    ? [['html'], ['json', { outputFile: 'test-results/results.json' }]]
    : [['list']],
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
});
```

**Rationale**: `forbidOnly` prevents `.only` leaking to CI. `trace: 'on-first-retry'` captures diagnostics without storage overhead on passing tests.

### RULE-PW-002: Sharding in CI [warn]

CI pipelines with >50 test files must use sharding:

```yaml
strategy:
  matrix:
    shardIndex: [1, 2, 3, 4]
    shardTotal: [4]
steps:
  - run: npx playwright test --shard=${{ matrix.shardIndex }}/${{ matrix.shardTotal }}
```

### RULE-PW-003: Global Setup and Teardown [error]

Use `globalSetup` and `globalTeardown` for shared auth state and data cleanup:

```typescript
// playwright.config.ts
export default defineConfig({
  globalSetup: require.resolve('./tests/e2e/global-setup'),
  globalTeardown: require.resolve('./tests/e2e/global-teardown'),
});
```

---

## Section 2: Test Structure

### RULE-PW-010: Describe Blocks [error]

Every test file must use a top-level `test.describe` block. Group by feature or user story.

```typescript
test.describe('Feature: Invoice Management', () => {
  test('PROJ-456 Create invoice with line items', { tag: ['@Smoke', '@Invoicing'] }, async ({ invoicePage }) => {
    // ...
  });
});
```

### RULE-PW-011: Test Naming [error]

Format: `<TICKET-ID> <Action> <Subject> <Condition>` (ticket ID optional for exploratory tests).

```typescript
// ✅ 'PROJ-123 Create resource with special characters in name'
// ✅ 'Verify dashboard loads for read-only user'
// ❌ 'test creation'
// ❌ 'it works'
```

### RULE-PW-012: Test Tags [error]

Every test must have at least one tag. Standard tags:

| Tag | Purpose | CI Gate |
|-----|---------|---------|
| `@Smoke` | Critical path, runs every PR | Required pass |
| `@Regression` | Full suite, runs nightly | Required pass |
| `@Flaky` | Known instability, tracked for fix | Excluded from gate |
| `@Visual` | Screenshot comparison tests | Separate pipeline |
| `@A11y` | Accessibility checks | Required pass |

### RULE-PW-013: Step Documentation [warn]

Wrap UI/API action sequences in `test.step()`. Maximum 4 actions per step. Label describes user intent, not implementation.

```typescript
await test.step('Submit registration form with valid data', async () => {
  await registrationPage.fillDetails(userData);
  await registrationPage.acceptTerms();
  await registrationPage.submit();
});
```

### RULE-PW-014: Test Isolation [error]

Tests must be completely independent. No shared mutable state between tests. Each test creates its own data and cleans up via fixtures or API.

```typescript
// ✅ Self-contained
test('Edit resource name', async ({ apiHelpers, resourcePage }) => {
  const resource = await apiHelpers.createResource({ name: `Resource-${crypto.randomUUID()}` });
  await resourcePage.navigateTo(resource.id);
  await resourcePage.editName('Updated Name');
  await expect(resourcePage.nameHeading).toHaveText('Updated Name');
});
```

---

## Section 3: Fixtures and Dependency Injection

### RULE-PW-020: Fixture-Based DI [error]

Never instantiate page objects or helpers manually. Inject via Playwright fixtures.

```typescript
// ✅ Correct
test('Submit form', async ({ loginPage, dashboardPage }) => { /* ... */ });

// ❌ Prohibited
test('Submit form', async ({ page }) => {
  const loginPage = new LoginPage(page);
});
```

### RULE-PW-021: Fixture-Based Teardown [error]

Use fixture teardown for guaranteed cleanup, not decorators or global registries.

```typescript
// fixtures.ts
export const test = base.extend<{ testResource: Resource }>({
  testResource: async ({ apiClient }, use) => {
    const resource = await apiClient.createResource({
      name: `Test-${crypto.randomUUID()}`,
    });
    await use(resource);
    // Teardown: runs even on test failure
    await apiClient.deleteResource(resource.id);
  },
});
```

**Rationale**: Fixture teardown is guaranteed by Playwright's test runner. Custom decorators and global registries can silently fail, leaving orphaned test data.

### RULE-PW-022: Authentication Fixtures [error]

Use `storageState` for auth. Never log in via UI unless testing the login flow itself.

```typescript
// auth.setup.ts
setup('authenticate as admin', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.ADMIN_EMAIL!);
  await page.getByLabel('Password').fill(process.env.ADMIN_PASSWORD!);
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.context().storageState({ path: '.auth/admin.json' });
});

// playwright.config.ts
projects: [
  { name: 'setup', testMatch: /.*\.setup\.ts/ },
  {
    name: 'chromium',
    dependencies: ['setup'],
    use: { storageState: '.auth/admin.json' },
  },
],
```

---

## Section 4: Page Objects and Locators

### RULE-PW-030: Locator Strategy [error]

Prefer accessible locators in this order:

1. `getByRole()` (best: semantic, resilient)
2. `getByLabel()`, `getByPlaceholder()`, `getByText()` (good: user-visible)
3. `getByTestId()` (acceptable: stable but not semantic)
4. CSS/XPath selectors (prohibited except for legacy migration)

### RULE-PW-031: Locator Encapsulation [warn]

Define locators as readonly properties in page objects. Compose in methods.

```typescript
class InvoicePage {
  readonly page: Page;
  private readonly saveButton: Locator;
  private readonly totalField: Locator;

  constructor(page: Page) {
    this.page = page;
    this.saveButton = page.getByRole('button', { name: 'Save' });
    this.totalField = page.getByTestId('invoice-total');
  }

  async save(): Promise<void> {
    await this.saveButton.click();
  }

  async getTotal(): Promise<string> {
    return this.totalField.textContent() ?? '';
  }
}
```

**Tradeoff**: This adds boilerplate vs. inline `getByRole()` calls. The benefit is centralized selector maintenance as the suite scales beyond ~20 page objects.

### RULE-PW-032: No Locators in Test Files [error]

Test files must not contain raw locator calls. All element interaction goes through page objects or fixture helpers.

---

## Section 5: Synchronization and Stability

### RULE-PW-040: Network-Aware Actions [error]

UI actions triggering network requests must use `Promise.all` with `waitForResponse`:

```typescript
await Promise.all([
  page.waitForResponse(resp => resp.url().includes('/api/invoices') && resp.status() === 200),
  invoicePage.save(),
]);
```

### RULE-PW-041: Prohibited Wait Patterns [error]

| Prohibited | Replacement |
|------------|-------------|
| `page.waitForTimeout()` | Locator assertions (`expect(locator).toBeVisible()`) |
| `page.waitForLoadState('networkidle')` | `waitForResponse` on specific endpoints |
| `page.waitForSelector()` | `expect(locator).toBeVisible()` or `toBeAttached()` |
| `sleep()`, `forceWait()` | Event-driven waits or polling assertions |

### RULE-PW-042: Eventual Consistency [warn]

For async backend operations (search indexing, background jobs), use polling with timeout:

```typescript
await expect(async () => {
  const results = await apiClient.search(resourceName);
  expect(results).toHaveLength(1);
}).toPass({ timeout: 15_000, intervals: [1_000, 2_000, 5_000] });
```

**Rationale**: `toPass()` is Playwright's built-in retry mechanism. Prefer over custom polling loops.

---

## Section 6: Test Data

### RULE-PW-050: Unique Identifiers [error]

Use `crypto.randomUUID()` for all test entity names. Never use `Date.now()`.

```typescript
// ✅ Parallel-safe
const name = `Invoice-${crypto.randomUUID()}`;

// ❌ Collision-prone under parallelism
const name = `Invoice-${Date.now()}`;
```

### RULE-PW-051: API-First Data Setup [error]

Create prerequisite data via API. UI creation only when testing the creation flow itself.

```typescript
// ✅ API setup, UI verification
const invoice = await apiHelpers.createInvoice(testData);
await invoiceListPage.navigateTo();
await expect(invoiceListPage.getRow(invoice.id)).toBeVisible();
```

---

## Section 7: Assertions

### RULE-PW-060: Soft Assertions for Multi-Field Checks [warn]

Use `expect.soft()` when verifying 3+ related fields. Collects all failures before reporting.

```typescript
await test.step('Verify invoice details', async () => {
  expect.soft(details.number).toBe(expected.number);
  expect.soft(details.total).toBe(expected.total);
  expect.soft(details.status).toBe('Draft');
});
```

### RULE-PW-061: No Toast-Based Verification [error]

Never verify business outcomes via transient UI notifications. Use API or stable DOM elements.

```typescript
// ✅ Verify via API state
const status = await apiClient.getInvoiceStatus(invoiceId);
expect(status).toBe('sent');

// ❌ Verify via toast
await expect(page.getByText('Invoice sent successfully')).toBeVisible();
```

### RULE-PW-062: Visual Regression [info]

Use `toHaveScreenshot()` for UI-heavy components. Store baselines in version control.

```typescript
await expect(page).toHaveScreenshot('dashboard-default.png', {
  maxDiffPixelRatio: 0.01,
});
```

### RULE-PW-063: Accessibility Assertions [warn]

Include `@axe-core/playwright` checks for critical user flows.

```typescript
import AxeBuilder from '@axe-core/playwright';

test('Dashboard meets a11y standards', { tag: ['@A11y'] }, async ({ page }) => {
  await page.goto('/dashboard');
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);
});
```

---

## Section 8: Imports and Code Quality

### RULE-PW-070: Path Aliases [error]

Use path aliases. No relative imports beyond one level.

```typescript
// ✅ import { InvoicePage } from '@pages/InvoicePage';
// ❌ import { InvoicePage } from '../../../pages/InvoicePage';
```

### RULE-PW-071: Async Discipline [error]

Every `Promise`-returning call must be `await`ed. Missing `await` causes silent race conditions.

### RULE-PW-072: Parallel API Calls [info]

Execute independent API operations concurrently:

```typescript
const [invoice, customer] = await Promise.all([
  apiClient.createInvoice(invoiceData),
  apiClient.createCustomer(customerData),
]);
```

---

## Section 9: CI/CD Integration

### RULE-PW-080: GitHub Actions Workflow [error]

Reference workflow for Playwright in CI:

```yaml
name: E2E Tests
on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * *' # Nightly regression

jobs:
  e2e:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        shardIndex: [1, 2, 3, 4]
        shardTotal: [4]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm

      - run: npm ci
      - run: npx playwright install --with-deps chromium

      - name: Run E2E (shard ${{ matrix.shardIndex }}/${{ matrix.shardTotal }})
        run: npx playwright test --shard=${{ matrix.shardIndex }}/${{ matrix.shardTotal }}
        env:
          BASE_URL: ${{ vars.STAGING_URL }}

      - name: Upload test artifacts
        if: ${{ !cancelled() }}
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report-${{ matrix.shardIndex }}
          path: |
            playwright-report/
            test-results/
          retention-days: 14

      - name: Upload blob report (for merge)
        if: ${{ !cancelled() }}
        uses: actions/upload-artifact@v4
        with:
          name: blob-report-${{ matrix.shardIndex }}
          path: blob-report/
          retention-days: 1
```

### RULE-PW-081: Smoke Gate on PR [error]

PRs must run `@Smoke` tagged tests as a required status check:

```bash
npx playwright test --grep @Smoke
```

### RULE-PW-082: Trace Artifact Retention [warn]

Upload traces and screenshots for failed tests. Retain for 14 days minimum.

---

## Appendix A: File Structure Convention

```
tests/
  e2e/
    fixtures/
      index.ts           # Combined fixture exports
      auth.fixture.ts    # Auth-related fixtures
      data.fixture.ts    # Test data factories
    pages/
      LoginPage.ts
      DashboardPage.ts
    helpers/
      api-client.ts      # Typed API helper
      search-helper.ts
    specs/
      auth/
        login.spec.ts
      invoicing/
        create-invoice.spec.ts
    global-setup.ts
    global-teardown.ts
  playwright.config.ts
  tsconfig.json            # Path alias config (@pages, @fixtures, @helpers)
```

## Appendix B: Rule Index

| Rule | Severity | Category |
|------|----------|----------|
| PW-001 | error | Configuration |
| PW-002 | warn | Configuration |
| PW-003 | error | Configuration |
| PW-010 | error | Test Structure |
| PW-011 | error | Test Structure |
| PW-012 | error | Test Structure |
| PW-013 | warn | Test Structure |
| PW-014 | error | Test Structure |
| PW-020 | error | Fixtures |
| PW-021 | error | Fixtures |
| PW-022 | error | Fixtures |
| PW-030 | error | Page Objects |
| PW-031 | warn | Page Objects |
| PW-032 | error | Page Objects |
| PW-040 | error | Synchronization |
| PW-041 | error | Synchronization |
| PW-042 | warn | Synchronization |
| PW-050 | error | Test Data |
| PW-051 | error | Test Data |
| PW-060 | warn | Assertions |
| PW-061 | error | Assertions |
| PW-062 | info | Assertions |
| PW-063 | warn | Assertions |
| PW-070 | error | Code Quality |
| PW-071 | error | Code Quality |
| PW-072 | info | Code Quality |
| PW-080 | error | CI/CD |
| PW-081 | error | CI/CD |
| PW-082 | warn | CI/CD |
