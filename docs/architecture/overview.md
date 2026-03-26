# Architecture Overview

## Stack

| Layer | Technology |
|-------|-----------|
| Web framework | Rails (Ruby 3.3.6) |
| Database | PostgreSQL |
| Background jobs | Sidekiq + Redis |
| File storage | AWS S3 (dev: local) |
| Email | GOV.UK Notify |
| Auth | Devise + Azure AD (OmniAuth) |
| Authorization | Pundit |
| Templating | Slim |
| Frontend | Vanilla JS modules + SCSS |
| PDF generation | pdf-forms / PdfMakerJob |
| Excel reports | caxlsx |

## Key Patterns

**Decorators** (`app/decorators/`) — Draper-based; wrap models for view presentation. Never add view logic to models or helpers.

**Services** (`app/services/`) — One class per business operation (e.g. `CaseCreateService`, `CaseClosureService`). Controllers delegate to services.

**Policies** (`app/policies/`) — Pundit. Each case type has its own policy inheriting from `Case::BasePolicy`. Always check policy before adding controller actions.

**State machines** (`app/state_machines/`) — Configurable AASM-like machines per case type. Events drive all state transitions. See `state_machines.md`.

**Jobs** (`app/jobs/`) — Sidekiq workers for async ops: PDF generation, search indexing, email status, anonymisation.

**Stats/Reports** (`app/services/stats/`) — Named `R###` (e.g. `R003`, `R205`). ETL pipeline feeds `warehouse/case_report` table.

## Org Hierarchy

```
BusinessGroup → Directorate → BusinessUnit → Team → User
```

Cases are assigned to Teams; Users belong to Teams via `TeamsUsersRole`.

## External Integrations

- **GOV.UK Notify** — transactional email
- **Azure AD** — SSO authentication
- **AWS S3** — attachment storage
- **DPS (Digital Prison Services)** — data for Offender SAR cases
- **RPI (Request Personal Information)** — v1 and v2 API endpoints

## Environment Config

`config/settings.yml` — base config, overridden by `settings.#{env}.yml` and env vars via `config` gem.
