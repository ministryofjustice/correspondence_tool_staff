# Agent Index — Correspondence Tool Staff

> **Read this file first. Load specialist docs only when the task requires it.**

## What This App Is
MoJ internal case management system for handling FOI, SAR (including Non-Offender SARs and Offender SARs), and related correspondence requests. Ruby on Rails monolith, PostgreSQL, Sidekiq, Redis, S3, GOV.UK Notify.

## Nomenclature
- The phrase "Branston" refers to the team with permission to work on Offender SARs and Complaints for Offender SARs.
- The phrase "London Disclosure" and "Disclosure" and "Disclosure Team" refers to the teams with permission to work on all other case types including FOIs, Standard SARs and SAR complaints.

## Docs
- `AGENTS.md` — full index and rules (read first)
- `docs/sessions/README.md` — in-progress work tracker (update at session end)
- `docs/architecture/` — domain model, state machines, system overview
- `docs/conventions/` — code, testing, git standards
- `docs/decisions/` — ADRs for architectural choices


## Docs Map

| File | Load when… |
|------|-----------|
| `architecture/overview.md` | Touching infrastructure, services, or unfamiliar patterns |
| `architecture/domain.md` | Working with case types, models, or business logic |
| `architecture/state_machines.md` | Changing case transitions, events, or workflow |
| `conventions/code.md` | Writing or reviewing any Ruby/Rails code |
| `conventions/testing.md` | Writing or running specs |
| `conventions/git.md` | Committing, branching, or creating PRs |
| `decisions/README.md` | Proposing architectural changes |
| `sessions/README.md` | Resuming in-progress work across sessions |

## Critical Rules (always apply)

- **Never skip tests** — run `bundle exec rspec <file>` for touched code
- **Pundit policies** govern all access — check `app/policies/` before adding actions
- **State machine** is in `app/state_machines/` — do not bypass it via direct DB writes
- **Decorators not helpers** — presentation logic lives in `app/decorators/`
- **Services not fat controllers** — business logic lives in `app/services/`
- Branch naming: `<agent>/<slug>` (already set by worktree)
- PR target: `main`

## Non-Negotiables
- Run specs for any code you touch: `bundle exec rspec spec/path/to/file_spec.rb`
- Never bypass state machines with direct DB writes
- Always `authorize` in controllers via Pundit
- Services for logic, decorators for presentation, policies for access

## Key Entry Points

```
app/models/case/base.rb          # Core case model
app/state_machines/              # All workflow transitions
app/policies/case/base_policy.rb # Authorization root
app/services/                    # Business logic layer
config/routes.rb                 # All routes
spec/                            # RSpec suite (parallel_tests)
```

## Running Tests

```bash
bundle exec rspec spec/path/to/file_spec.rb          # single file
bundle exec parallel_rspec spec/                     # full suite (parallel; uses available cores)
bundle exec parallel_rspec -n <workers> spec/        # full suite with explicit worker count
bundle exec rspec --format documentation spec/...    # verbose
```
### When Docker Compose is used 

Check `docker-compose.yml` for details and ping the service to test it is running using `docker compose ps`. If the app is running in Docker, you need to prefix all commands with `docker compose exec spec --` to run them inside the container. For example, to run tests, you would use:

```bash
docker compose exec spec -- bundle exec rspec spec/path/to/file_spec.rb
```


