# Git & PR Conventions

## Branch Naming

```
claude/<short-slug>     # agentic work (auto-set by worktree)
feature/<ticket>-slug   # human feature branches
fix/<ticket>-slug       # bug fixes
```

## Commit Style

Follow existing commits in this repo:

```
[CDPTKAN-123] Short imperative summary (#PR)

Longer explanation if needed. Keep subject under 72 chars.
```

Ticket ref `[CDPTKAN-NNN]` is required where a Jira ticket exists.

## PR Checklist

- [ ] Tests added/updated for changed code
- [ ] Rubocop passes (`bundle exec rubocop <files>`)
- [ ] No direct state machine bypasses
- [ ] Pundit policy covers new actions
- [ ] i18n keys added to `config/locales/` if new user-facing text
- [ ] Migration has a corresponding data migration if needed

## PR Target

Always target `main`.

## Merge Strategy

Squash-merge preferred for small features. Merge commit for larger multi-commit PRs.

## Do Not

- Force-push to `main`
- Commit with `--no-verify`
- Amend published commits
