# Agent-Testable Architecture

> **When to apply:** New services, greenfield projects, and any codebase agents will operate on
> **Maturity Level:** All levels; highest payoff at MVP, most expensive to retrofit at Production

Four rules that make a system deployable on day one and fully exercisable by an agent
without a browser.

---

## Rule 1 — Ship a walking skeleton before any feature logic

A thin end-to-end slice reaches a hosted environment before the domain model is designed.

| Requirement | Done means |
|-------------|------------|
| Pipeline | commit → build → test → deploy runs unattended, no manual steps |
| Environment | reachable on a real hosted domain, not localhost |
| Integrations | every external service is wired, even if the call returns a stub |
| Tests | unit gate before build, smoke test after deploy |
| Timebox | working on day 1; if it slips past day 2, cut feature scope, not the skeleton |

**Anti-pattern:** "we will wire up deployment once the domain settles." Deployment
discovered late is deployment discovered in a crisis.

**Verification:** `git log` shows a deploy to the hosted URL on the first commit day.

**Relationship to tracer bullets:** a tracer bullet proves the *architecture* end to end
(see `base/architecture-principles.md` → Tracer Bullet Development). A walking skeleton
proves the *delivery pipeline* end to end. Build them as one slice — the tracer bullet is
what the pipeline deploys.

---

## Rule 2 — Domain logic imports no I/O (ports and adapters)

| Layer | May import | Must not import |
|-------|-----------|-----------------|
| Domain | stdlib, own types | SDKs, ORMs, HTTP clients, framework decorators |
| Ports | domain types | anything concrete |
| Adapters | SDKs, drivers, frameworks | other adapters |

- Every outbound dependency sits behind a port the domain owns.
- Swapping Postgres for DynamoDB, or a live provider for a fake, touches adapters only.
- Domain tests run with no network, no containers, no fixtures beyond in-memory fakes.

**Verification:** if a domain test needs a container or a credential, the boundary is
wrong. Enforce with an import-linter contract in CI, not code review.

See `base/architecture-principles.md` → Hexagonal/Clean Architecture for the port and
adapter structure this rule enforces. The addition here is that the boundary is a
*CI-enforced contract*, not a convention.

---

## Rule 3 — Every use case has at least two front doors

The HTTP handler and the CLI command are both thin callers of the same application
service. Neither holds business rules.

```
                 ┌──> HTTP adapter ──┐
domain + ports <─┤                   ├──> application service (single implementation)
                 └──> CLI adapter  ──┘
```

- A use case is exposed in both surfaces or neither.
- Handler and command bodies stay under ~20 lines: parse, call, format.

**Verification:** every GUI action has a CLI equivalent. Track the gap as a
traceability row, not a backlog wish (see `base/specification-driven-development.md` →
Traceability Matrix).

---

## Rule 4 — Design the CLI as the agent's test harness

| Property | Requirement |
|----------|-------------|
| Non-interactive | no prompts by default; every input available as a flag |
| Machine-readable | `--json` on every command; human format is the fallback, not the contract |
| Exit codes | 0 success, non-zero failure, distinct codes per failure class |
| Deterministic | injectable clock, seedable randomness, `--dry-run` |
| Composable | reads stdin, writes stdout, errors to stderr |
| Self-describing | `--help` and a machine-readable command list agents can enumerate |

An agent drives full scenarios through this surface, including exploratory runs that
find edge cases no one specified.

**Verification:** every edge case an agent discovers is promoted to a named acceptance
test with a spec ID before the fix merges. Discovery without promotion is a one-time
finding, not a regression guard.

See `base/tool-design.md` for the general CLI ergonomics these properties build on, and
`base/testing-atdd.md` for promoting a discovered case into an acceptance test.

---

## Checklist

- [ ] Hosted deploy exists before feature work starts
- [ ] CI enforces the domain import ban
- [ ] Domain test suite runs offline in under 10s
- [ ] Every use case reachable from both HTTP and CLI
- [ ] Every command supports `--json` and a non-zero failure exit code
- [ ] Agent-discovered edge cases traced to acceptance tests

---

## Tradeoffs

| Rule | Cost | When to skip |
|------|------|--------------|
| Walking skeleton | day 1 spent on plumbing, zero demoable features | never for services; skip for throwaway spikes |
| Ports and adapters | indirection tax on thin CRUD; two files per dependency | single-model CRUD apps with one persistence target and no agent testing |
| Dual front doors | ~20-30% more surface to maintain and document | internal tools where the CLI is the only door |
| Agent-driven CLI | flaky or non-deterministic commands generate noisy findings | until determinism is in place, the harness costs more than it returns |

---

## Related Resources

- `base/architecture-principles.md` - Tracer bullets, hexagonal architecture, dependency inversion
- `base/tool-design.md` - CLI ergonomics, structured output, composability
- `base/cicd-comprehensive.md` - Pipeline stages the walking skeleton runs through
- `base/testing-atdd.md` - Promoting discovered edge cases into acceptance tests
- `base/specification-driven-development.md` - Spec IDs and the traceability matrix
- `base/lean-development.md` - Progressive enhancement after the skeleton lands
- `base/project-maturity-levels.md` - Which rules are required at which maturity level
