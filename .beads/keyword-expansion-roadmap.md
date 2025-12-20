# Keyword Expansion Roadmap for skill-rules.json

## Purpose
This document tracks potential keyword mappings for `.claude/skills/skill-rules.json` that were identified but removed due to missing rule files or overly generic keywords that cause false positives.

## Guiding Principles

### ✅ Good Keywords (Keep)
- **Specific package names**: `@tanstack/react-query`, `@prisma/client`, `@testing-library/react`
- **Unique tool names**: `playwright`, `cypress`, `vitest`, `turborepo`
- **Specific function/hook names**: `useMutation`, `useQuery`, `useNavigate`, `useForm`
- **Unambiguous terms**: `tailwindcss`, `styled-components`, `testcontainers`

### ❌ Bad Keywords (Avoid)
- **Generic terms**: `schema`, `validate`, `parse`, `cache`, `migration`
- **Common words**: `test data`, `import`, `render`, `screen`
- **Ambiguous terms**: `e2e`, `integration`, `mock` (unless very context-specific)
- **Overly broad**: `sql`, `database`, `container` (without qualifiers)

### 🔑 Rule
**Keywords must be added ONLY after:**
1. ✅ Corresponding rule file exists
2. ✅ Keyword is specific enough to avoid false positives
3. ✅ Testing confirms no context saturation

---

## Pending Tool Categories

### 1. Build Tools & Bundlers
**Status**: ⏸️ Blocked - Rule files needed
**Target Rule Files**: `tools/vite/`, `tools/turborepo/`, `tools/nx/`, `tools/pnpm/`

| Tool | Specific Keywords | Generic Keywords to Avoid | Priority |
|------|-------------------|---------------------------|----------|
| **Vite** | `vite.config`, `vite build`, `vite dev` | `vite` (too short) | High |
| **Turborepo** | `turbo.json`, `turborepo` | `turbo`, `monorepo` | Medium |
| **Nx** | `nx.json`, `nx workspace`, `@nx/` | `nx` (too short) | Medium |
| **pnpm** | `pnpm-workspace.yaml`, `pnpm-lock.yaml` | `pnpm` | Medium |
| **Webpack** | `webpack.config`, `webpackConfig` | `webpack` | Low |
| **Rollup** | `rollup.config`, `@rollup/` | `rollup` | Low |
| **esbuild** | `esbuild.config`, `esbuild bundle` | `esbuild` | Low |

**Rule Files Needed**:
- [ ] `tools/vite/best-practices.md`
- [ ] `tools/turborepo/best-practices.md`
- [ ] `tools/nx/best-practices.md`
- [ ] `tools/pnpm/best-practices.md`

---

### 2. Infrastructure & Container Orchestration
**Status**: ⏸️ Blocked - Rule files needed
**Target Rule Files**: `infrastructure/docker/`, `infrastructure/kubernetes/`

| Tool | Specific Keywords | Generic Keywords to Avoid | Priority |
|------|-------------------|---------------------------|----------|
| **Docker** | `Dockerfile`, `docker-compose.yml`, `docker build` | `container`, `image` | High |
| **Kubernetes** | `kubectl`, `k8s`, `deployment.yaml`, `pod.yaml` | `pod`, `deployment` | High |
| **Helm** | `helm install`, `Chart.yaml`, `values.yaml` | `helm` | Medium |
| **Ansible** | `playbook.yml`, `ansible-playbook` | `ansible`, `playbook` | Medium |
| **Terraform** | `terraform.tf`, `terraform plan`, `terraform apply` | `terraform` | Medium |

**Rule Files Needed**:
- [ ] `infrastructure/docker/best-practices.md`
- [ ] `infrastructure/kubernetes/best-practices.md`
- [ ] `infrastructure/helm/best-practices.md`
- [ ] `infrastructure/ansible/best-practices.md`

---

### 3. Database & ORM Tools
**Status**: ⏸️ Blocked - Rule files needed
**Target Rule Files**: `tools/prisma/`, `tools/redis/`, `base/database-patterns.md`

| Tool | Specific Keywords | Generic Keywords to Avoid | Priority |
|------|-------------------|---------------------------|----------|
| **Prisma** | `@prisma/client`, `prisma migrate`, `schema.prisma` | `prisma` | High |
| **TypeORM** | `@Entity()`, `@Column()`, `typeorm` | `entity`, `column` | Medium |
| **Sequelize** | `sequelize.define`, `sequelize-cli` | `sequelize` | Medium |
| **Redis** | `redis-py`, `ioredis`, `redis.createClient` | `redis`, `cache` | High |
| **MongoDB** | `mongoose.Schema`, `mongodb://`, `@mongodb/` | `mongodb`, `mongo` | Medium |
| **PostgreSQL** | `pg-promise`, `psycopg2`, `CREATE TABLE` | `postgres`, `sql` | Low |

**Rule Files Needed**:
- [ ] `tools/prisma/best-practices.md`
- [ ] `tools/redis/best-practices.md`
- [ ] `tools/typeorm/best-practices.md`
- [ ] `base/database-patterns.md`

---

### 4. Data Validation Libraries
**Status**: ⏸️ Blocked - Rule file needed + keywords too generic
**Target Rule Files**: `base/data-validation.md`

| Tool | Specific Keywords | Generic Keywords to Avoid | Priority |
|------|-------------------|---------------------------|----------|
| **Zod** | `z.object`, `z.string`, `z.infer` | `zod`, `schema` | High |
| **Joi** | `Joi.object()`, `Joi.string()` | `joi`, `validate` | Medium |
| **Yup** | `yup.object()`, `yup.string()` | `yup`, `schema` | Medium |
| **Ajv** | `ajv.compile`, `ajv validate` | `ajv` | Low |

**Issues to Resolve**:
- ⚠️ `schema`, `validate`, `parse` are too generic
- ✅ Use method-specific keywords instead: `z.object`, `Joi.string()`

**Rule Files Needed**:
- [ ] `base/data-validation.md` (covering schema validation patterns)

---

### 5. Testing Tools (Partially Complete)
**Status**: ✅ Core tools added, ecosystem tools pending
**Current Coverage**: vitest, playwright, cypress, testcontainers, @testing-library/react

| Tool | Specific Keywords | Generic Keywords to Avoid | Priority |
|------|-------------------|---------------------------|----------|
| **Storybook** | `@storybook/react`, `.stories.tsx`, `storiesOf` | `storybook`, `story` | Medium |
| **Chromatic** | `chromatic --`, `chromatic.config` | `chromatic` | Low |
| **Percy** | `@percy/`, `percy snapshot` | `percy` | Low |
| **k6** | `k6 run`, `k6.io` | `k6` | Low |

**Additional Testing Keywords to Consider**:
- `jest.config`, `vitest.config`
- `test.skip`, `test.only`, `describe.each`
- `beforeEach`, `afterEach`, `beforeAll`, `afterAll`

---

### 6. React Ecosystem (Partially Complete)
**Status**: ✅ Core libraries added, additional tools pending
**Current Coverage**: @tanstack/react-query, useMutation, useQuery, useSWR, useNavigate, useForm, styled-components, tailwindcss

| Tool | Specific Keywords | Generic Keywords to Avoid | Priority |
|------|-------------------|---------------------------|----------|
| **Storybook** | `@storybook/react`, `.stories.tsx` | `story`, `storybook` | Medium |
| **Formik** | `useFormik`, `<Formik>` | `formik` | Low |
| **Redux Toolkit** | `createSlice`, `configureStore`, `@reduxjs/toolkit` | `redux`, `store` | Medium |
| **Zustand** | `create()` from `zustand` | `zustand` | Low |
| **Jotai** | `atom`, `useAtom` from `jotai` | `jotai` | Low |

---

### 7. API & HTTP Libraries
**Status**: ⏸️ Not started
**Target Rule Files**: `tools/axios/`, `base/api-design.md`

| Tool | Specific Keywords | Generic Keywords to Avoid | Priority |
|------|-------------------|---------------------------|----------|
| **Axios** | `axios.get`, `axios.post`, `axiosInstance` | `axios` | High |
| **Fetch API** | `fetch()`, `Response`, `Request` | `fetch` | Low |
| **tRPC** | `createTRPCRouter`, `procedure`, `trpc` | `rpc` | Medium |
| **GraphQL** | `useQuery` (conflicts!), `gql`, `@apollo/client` | `graphql`, `query` | Medium |

**Conflict Warning**: `useQuery` is used by both React Query and GraphQL

---

### 8. State Management
**Status**: ⏸️ Not started
**Target Rule Files**: `frameworks/react/state-management.md`

| Tool | Specific Keywords | Generic Keywords to Avoid | Priority |
|------|-------------------|---------------------------|----------|
| **Redux Toolkit** | `createSlice`, `createAsyncThunk`, `configureStore` | `redux`, `slice` | Medium |
| **Zustand** | `create((set, get)` | `zustand` | Low |
| **Jotai** | `atom`, `useAtom` | `jotai`, `atom` | Low |
| **Recoil** | `atom`, `selector`, `useRecoilState` | `recoil` | Low |

---

### 9. Linting & Formatting
**Status**: ⏸️ Not started
**Target Rule Files**: `tools/eslint/`, `tools/prettier/`

| Tool | Specific Keywords | Generic Keywords to Avoid | Priority |
|------|-------------------|---------------------------|----------|
| **ESLint** | `.eslintrc`, `eslint-config-`, `eslint-plugin-` | `eslint`, `lint` | Medium |
| **Prettier** | `.prettierrc`, `prettier-plugin-` | `prettier`, `format` | Medium |
| **Biome** | `biome.json`, `@biomejs/` | `biome` | Low |
| **Stylelint** | `.stylelintrc`, `stylelint-config-` | `stylelint` | Low |

---

### 10. Cloud Platforms (Partially Complete)
**Status**: ✅ AWS covered, others pending
**Current Coverage**: AWS (comprehensive)

| Platform | Specific Keywords | Generic Keywords to Avoid | Priority |
|----------|-------------------|---------------------------|----------|
| **Vercel** | `vercel.json`, `vercel deploy`, `edge function` | `vercel` | High |
| **Netlify** | `netlify.toml`, `netlify functions` | `netlify` | Medium |
| **Railway** | `railway.json`, `railway up` | `railway` | Low |
| **Fly.io** | `fly.toml`, `flyctl` | `fly` | Low |

---

## Implementation Workflow

### Step 1: Create Rule File
```bash
# Example for Prisma
mkdir -p tools/prisma
touch tools/prisma/best-practices.md
# Write comprehensive best practices based on frameworks/react/best-practices.md template
```

### Step 2: Add Specific Keywords Only
```json
"prisma": {
  "keywords": ["@prisma/client", "prisma migrate", "schema.prisma", "prisma.schema"],
  "rules": ["tools/prisma/best-practices"]
}
```

### Step 3: Test Activation
- Create test prompts with the keywords
- Verify rule activation doesn't cause false positives
- Check context usage doesn't spike

### Step 4: Update This Roadmap
- Mark as complete
- Document any issues discovered
- Update priority based on real-world usage

---

## Metrics to Track

| Metric | Target | Warning Threshold |
|--------|--------|-------------------|
| Keywords per category | 5-15 | >20 |
| False positive rate | <5% | >10% |
| Context tokens added per activation | <10K | >25K |
| Rule file activation time | <500ms | >1s |

---

## Recently Removed (v1.2.0)

These were removed due to missing rule files or generic keywords:

### Removed Testing Keywords
- ❌ `e2e`, `integration test` (too generic, covered by intent patterns)
- ❌ `render`, `screen`, `userEvent` (too generic, used in many contexts)
- ❌ `msw`, `mock service worker` (covered by existing `mock` keyword)
- ❌ `snapshot test` (too generic)

### Removed React Keywords
- ❌ `react query`, `swr`, `react router` (space-separated, less specific)
- ❌ `Route` (too generic, conflicts with Express routes)
- ❌ `react hook form`, `tailwind`, `storybook` (less specific variants)

### Removed Sections
- ❌ `tools` (vite, turborepo, nx, pnpm) - no rule files
- ❌ `infrastructure` (docker, kubernetes, ansible) - no rule files
- ❌ `database` (prisma, redis, sql) - no rule files
- ❌ `dataValidation` (zod, joi, yup) - no rule file + generic keywords

---

## Related Issues

- `centralized-rules-sfu`: Build tools keywords
- `centralized-rules-cp1`: Infrastructure keywords
- `centralized-rules-67y`: Data validation keywords
- `centralized-rules-lpt`: Database/ORM keywords

---

## Notes

- **Version**: 1.0
- **Last Updated**: 2025-12-20
- **Maintainer**: Generated during v1.2.0 cleanup
- **Next Review**: After 5 new rule files are created
