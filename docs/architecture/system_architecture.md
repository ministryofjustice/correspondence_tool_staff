# High-Level System Architecture

This document describes the main runtime boundaries, supporting infrastructure, and external integrations for the Correspondence Tool Staff application.

## Overview

Correspondence Tool Staff is a Rails monolith used by MoJ staff to manage FOI, SAR, ICO, and related correspondence workflows. The application exposes two main entry points:

- an authenticated staff web UI for operational casework
- a small API surface for inbound Request Personal Information (RPI) submissions

The codebase is organised as a classic Rails monolith with domain models, service objects, Pundit policies, Draper decorators, state-machine driven workflows, and Sidekiq-backed asynchronous processing.

## System Diagram

```mermaid
flowchart LR
    staff[Internal MoJ Staff\nBrowser UI] -->|HTTPS| web
    rpi_client[Upstream RPI Submitter\nfor example MoJ Forms] -->|Encrypted JWE payload| api
    azure[Azure AD] -->|SSO via OmniAuth| web

    subgraph cts[Correspondence Tool Staff\nRails Monolith Boundary]
        web[Web Layer\nControllers + Slim Views + jQuery/Vanilla JS]
        api[API Layer\nRPI and RPI v2 endpoints]
        auth[AuthN/AuthZ\nDevise + Pundit]
        domain[Domain Layer\nCase models, assignments, attachments, retention, linked cases]
        workflows[Workflow Engine\nConfigurable state machines + transition hooks]
        services[Application Services\nCase operations, notifications, uploads, reporting]
        reports[Reporting and Warehouse Projection\nStats services + warehouse_case_reports]
        jobs[Async Workers\nSidekiq queues for background, warehouse, email, RPI, PDF]
        docs[Document Processing\nLibreconv/PDF preview generation]
    end

    web --> auth
    api --> auth
    web --> domain
    api --> services
    auth --> domain
    domain --> workflows
    workflows --> services
    services --> reports
    services --> jobs
    jobs --> docs
    jobs --> services

    domain -->|ActiveRecord| postgres[(PostgreSQL)]
    reports -->|warehouse_case_reports and report data| postgres
    jobs -->|queue state and ephemeral report payloads| redis[(Redis)]
    web -->|healthcheck queries| redis

    services -->|case attachments and generated files| s3[AWS S3]
    jobs -->|attachment zips and previews| s3
    services -->|transactional emails| notify[GOV.UK Notify]
    jobs -->|queued mail delivery and status checks| notify
    web -->|error and exception reporting| sentry[Sentry]
    api -->|error and exception reporting| sentry
    jobs -->|job error reporting| sentry
```

## Runtime Shape

- Web process: Rails application serving the staff UI and API endpoints.
- Worker processes: Sidekiq queues are split by concern in development into background, warehouse, and quick/email workers.
- Data store: PostgreSQL holds both transactional case data and reporting projections such as `warehouse_case_reports`.
- Queue/cache store: Redis supports Sidekiq and is also used for temporary report payload storage.

## Internal Design Boundaries

- Presentation: Slim templates with jQuery and vanilla JavaScript for staff-facing workflows.
- Authentication: Devise with Azure Active Directory OmniAuth.
- Authorization: Pundit policies, rooted in case policies.
- Domain model: `Case::Base` with specialised subclasses for FOI, SAR, Offender SAR, ICO, and overturned ICO flows.
- Workflow control: state transitions are driven by configured state machines and transition hooks, rather than direct status mutation.
- Business logic: service objects handle case lifecycle actions, uploads, notifications, and reporting.
- Reporting: warehouse projection tables and stats services power monthly and closed-case reports.
- Asynchronous work: Sidekiq handles RPI processing, PDF preview generation, warehouse sync, email status, and performance report generation.

## Verified External Dependencies

- Azure AD: staff single sign-on.
- AWS S3: attachment storage, generated file storage, and download links.
- GOV.UK Notify: transactional and workflow-triggered email delivery.
- PostgreSQL: primary relational datastore.
- Redis: Sidekiq backing store and transient report payload storage.
- Sentry: exception and job failure monitoring.

## Notes

- The reporting "warehouse" is an internal reporting projection within the application and database, not a separate external analytics platform.
- The RPI API is a distinct system boundary: inbound encrypted payloads are accepted by the Rails app, expanded into internal request records, then fulfilled asynchronously via Sidekiq, S3, and GOV.UK Notify.
- The architecture is operationally split into processes, but remains a single deployable monolith rather than a microservice-based system.

## C4 Views

### System Context

This view shows Correspondence Tool Staff as a single product in relation to its users and external services.

```mermaid
flowchart LR
    staff[Internal MoJ Staff\nCaseworkers, approvers, managers, admins]
    rpi_submitter[External RPI Submission Source\nfor example MoJ Forms]
    cts[Correspondence Tool Staff\nMoJ correspondence case management system]

    azure[Azure AD\nIdentity provider]
    notify[GOV.UK Notify\nEmail delivery]
    s3[AWS S3\nAttachment and generated file storage]
    sentry[Sentry\nMonitoring and exception tracking]

    staff -->|manage FOI, SAR, ICO and related workflows| cts
    rpi_submitter -->|submit encrypted RPI requests| cts
    cts -->|authenticate staff via SSO| azure
    cts -->|send operational and RPI emails| notify
    cts -->|store and retrieve files| s3
    cts -->|report exceptions and failures| sentry
```

### Container View

This view decomposes the monolith into deployable/runtime containers and supporting infrastructure.

```mermaid
flowchart TB
    staff[Internal MoJ Staff Browser]
    rpi_submitter[External RPI Submission Source]
    azure[Azure AD]
    notify[GOV.UK Notify]
    s3[AWS S3]
    sentry[Sentry]

    subgraph app[Correspondence Tool Staff]
        web[Web Application\nRails controllers, Slim views, API endpoints]
        workers[Worker Processes\nSidekiq queues: background, warehouse, quick/email, RPI, PDF]
        postgres[(PostgreSQL\ntransactional data + warehouse projections)]
        redis[(Redis\nSidekiq queues + transient report payloads)]
    end

    staff -->|HTTPS| web
    rpi_submitter -->|POST JWE payload| web
    web -->|SSO redirect and callback| azure
    web -->|read/write domain data| postgres
    web -->|enqueue jobs, health checks, fetch transient report payloads| redis
    web -->|direct uploads, downloads, presigned URLs| s3
    web -->|deliver synchronous mail actions| notify
    web -->|capture exceptions| sentry

    workers -->|process async workflows| postgres
    workers -->|consume and publish jobs| redis
    workers -->|send queued emails and check delivery state| notify
    workers -->|generate and manage previews, zips, attachments| s3
    workers -->|capture job failures| sentry
```

## Deployment And Runtime View

This view focuses on process boundaries and the main operational execution paths. It is intentionally runtime-oriented rather than code-oriented.

```mermaid
flowchart LR
    browser[Staff Browser] --> ingress
    upstream[Upstream RPI Client] --> ingress

    subgraph runtime[Application Runtime]
        ingress[Ingress / Load Balancer]

        subgraph pods[App Processes]
            web[Rails Web Process\nUI + API + health endpoints]
            sidekiq_bg[Sidekiq Background\ncase operations, email status, misc jobs]
            sidekiq_wh[Sidekiq Warehouse\nreport projection and closed-case ETL]
            sidekiq_quick[Sidekiq Quick/Email\nnotification and fast jobs]
            sidekiq_rpi[Sidekiq RPI/PDF\nRPI fulfilment and document conversion]
        end

        postgres[(PostgreSQL)]
        redis[(Redis)]
    end

    ingress --> web
    web --> postgres
    web --> redis

    web -->|enqueue async work| redis
    redis --> sidekiq_bg
    redis --> sidekiq_wh
    redis --> sidekiq_quick
    redis --> sidekiq_rpi

    sidekiq_bg --> postgres
    sidekiq_wh --> postgres
    sidekiq_quick --> postgres
    sidekiq_rpi --> postgres

    sidekiq_quick --> notify[GOV.UK Notify]
    sidekiq_rpi --> s3[AWS S3]
    sidekiq_rpi --> notify
    web --> s3
    web --> azure[Azure AD]

    web --> sentry[Sentry]
    sidekiq_bg --> sentry
    sidekiq_wh --> sentry
    sidekiq_quick --> sentry
    sidekiq_rpi --> sentry
```

Operational notes:

- The web tier remains the only HTTP entry point for both staff interactions and RPI API submissions.
- Sidekiq is logically split by queue responsibility, but all workers execute code from the same Rails monolith.
- Redis is both the Sidekiq transport and a transient store for some generated report payloads.
- PostgreSQL carries both operational case records and internal warehouse-style reporting projections.

## Domain And Workflow View

This view focuses on the main domain aggregates and the common case progression pattern used across FOI and SAR flows, with Offender SAR and ICO variants branching from the same core model.

```mermaid
flowchart TD
    subgraph org[Organisation and Access]
        user[User]
        team[Team]
        business_unit[Business Unit]
        directorate[Directorate]
        business_group[Business Group]
        role[TeamsUsersRole]
    end

    subgraph core[Core Case Domain]
        case_base[Case::Base]
        assignment[Assignment]
        transition[CaseTransition]
        attachment[CaseAttachment]
        linked_case[LinkedCase]
        retention[RetentionSchedule]
    end

    subgraph variants[Case Variants]
        foi[FOI Cases]
        sar[SAR Cases]
        offender[Offender SAR and Complaints]
        ico[ICO and Overturned ICO Cases]
    end

    subgraph offender_support[Offender SAR Support]
        dra[DataRequestArea]
        dr[DataRequest]
        cd[CommissioningDocument]
    end

    user --> role
    role --> team
    team --> business_unit
    business_unit --> directorate
    directorate --> business_group

    case_base --> assignment
    case_base --> transition
    case_base --> attachment
    case_base --> linked_case
    offender --> retention
    case_base --> foi
    case_base --> sar
    case_base --> offender
    case_base --> ico

    offender --> dra
    dra --> dr
    dra --> cd
    assignment --> user
    assignment --> team
```

```mermaid
flowchart LR
    intake[Case created or received]
    triage[Assignment and team routing]
    work[Drafting and casework]
    clearance[Review / clearance when required]
    dispatch[Awaiting dispatch / send]
    responded[Responded]
    closed[Closed]

    stop[Stop the clock]
    extend[Deadline extension]
    redraft[Redraft requested]
    ico_branch[ICO / complaint / overturned branch]

    intake --> triage --> work --> clearance --> dispatch --> responded --> closed
    work --> stop --> work
    work --> extend --> work
    clearance --> redraft --> work
    responded --> ico_branch
    ico_branch --> work
```

Workflow notes:

- State transitions are configured through YAML-backed state machines and executed through services rather than directly from controllers.
- Transition hooks trigger secondary behaviour such as responder notifications, team notifications, reassignment mail, and approver review notifications.
- Offender SAR introduces additional data-request and commissioning-document flows, while ICO and complaint cases branch from or link back to an original case.
