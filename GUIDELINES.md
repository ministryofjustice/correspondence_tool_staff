# Claude Code — Project Bootstrap

**Always read `docs/AGENTS.md` before starting any task.**

## One-Line Context
MoJ internal case management app for FOI, SAR, and related correspondence. Rails 7, PostgreSQL, Sidekiq, Pundit, Draper, configurable state machines.

## Non-Negotiables
- Run specs for any code you touch: `bundle exec rspec spec/path/to/file_spec.rb`
- Never bypass state machines with direct DB writes
- Always `authorize` in controllers via Pundit
- Services for logic, decorators for presentation, policies for access

## Docs
- `docs/AGENTS.md` — full index and rules (read first)
- `docs/sessions/README.md` — in-progress work tracker (update at session end)
- `docs/architecture/` — domain model, state machines, system overview
- `docs/conventions/` — code, testing, git standards
- `docs/decisions/` — ADRs for architectural choices
