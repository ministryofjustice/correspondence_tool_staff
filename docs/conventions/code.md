# Code Conventions

## Rails Patterns

| Rule | Detail |
|------|--------|
| Services for logic | `app/services/` — one class per operation, `#call` method |
| Decorators for views | `app/decorators/` — Draper; never put HTML in models |
| Policies for auth | `app/policies/` — Pundit; `authorize` in every controller action |
| Form objects | `app/form_models/` — for multi-step flows (Offender SAR) |
| Slim templates | All views are `.html.slim`; no `.erb` for new views |
| No logic in controllers | Controllers: authenticate → authorize → service → render |

## Naming

```ruby
# Services
CaseCreateService       # <Verb><Entity>Service
CaseFilterService       # namespace: app/services/case_filter/

# Decorators
Case::BaseDecorator     # mirrors model namespace

# Policies
Case::FOI::StandardPolicy

# Jobs
PdfMakerJob             # async
Warehouse::CaseSyncJob  # namespaced
```

## Case Number / References

Cases are numbered automatically via `CaseNumberCounter`. Never set manually.

## Rubocop

Config in `.rubocop.yml` / `.rubocop_todo.yml`. Run: `bundle exec rubocop app/path/to/file.rb`

## i18n

Strings in `config/locales/`. Use `I18n.t()` for all user-facing text. Missing key detection is automated in CI.

## Paper Trail

`CaseTransition` and key models use PaperTrail for audit. Never bypass with `without_versioning`.

## Key Gotchas

- `Case` is the STI base class in this app — always use a concrete subclass such as `Case::FOI::Standard`, never `Case` directly
- Assignments use roles: `responder`, `approver`, `manager` — see `TeamsUsersRole.roles.keys`
- Offender SAR has a separate stepped form flow — see `OffenderSarCaseForm`
- Stats reports are append-only ETL — do not update warehouse rows in place
