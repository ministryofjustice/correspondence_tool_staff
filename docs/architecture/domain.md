# Domain Model

## Case Type Hierarchy

```
Case::Base
├── Case::FOI::Standard
│   ├── Case::FOI::ComplianceReview
│   ├── Case::FOI::InternalReview
│   └── Case::FOI::TimelinessReview
├── Case::SAR::Standard
│   └── Case::SAR::InternalReview
├── Case::SAR::Offender
│   └── Case::SAR::OffenderComplaint
├── Case::ICO::Base
│   ├── Case::ICO::FOI
│   └── Case::ICO::SAR
└── Case::OverturnedICO::Base
    ├── Case::OverturnedICO::FOI
    └── Case::OverturnedICO::SAR
```

## Core Entities

| Model | Purpose |
|-------|---------|
| `Case::Base` | Root case model; all shared logic |
| `Assignment` | Links case to team/user with a role |
| `CaseTransition` | Audit log of every state change |
| `CaseAttachment` | S3-backed file on a case |
| `DataRequest` | External data fetch request (Offender SAR) |
| `DataRequestArea` | Groups DataRequests by source org |
| `CommissioningDocument` | Generated letter sent to external body |
| `Letter` / `LetterTemplate` | Correspondence templates |
| `RetentionSchedule` | Retention + anonymisation schedule |
| `Report` / `ReportType` | Generated stats reports |
| `LinkedCase` | Links related cases |

## Org / People

| Model | Purpose |
|-------|---------|
| `User` | Staff member; belongs to many teams via role |
| `Team` | Corresponds to a business unit or specialist team |
| `BusinessUnit` | Operational team with case handling responsibilities. Cases can be assigned to a BusinessUnit. |
| `Directorate` | Groups business units |
| `BusinessGroup` | Top-level org unit |
| `TeamsUsersRole` | Join: user ↔ team with a role label |
| `TeamCorrespondenceTypeRole` | What case types a team handles |

## Case Closure Models (`app/models/case_closure/`)

Used to record FOI/SAR closure metadata:
`Metadatum`, `Exemption`, `InfoHeldStatus`, `Outcome`, `RefusalReason`, `AppealOutcome`, `OffenderComplaintOutcome`

## Key Concerns (mixins)

| Concern | What it adds |
|---------|-------------|
| `CaseStates` | ConfigurableStateMachine-based state machine |
| `Searchable` | pg_search/tsvector full-text search (no Elasticsearch) |
| `Extendable` | SAR deadline extension logic |
| `Stoppable` | Stop-the-clock logic |
| `DraftTimeliness` | Tracks whether draft was timely |
| `Warehousable` | Syncs to warehouse reporting table |

## Important Relationships

- A case `has_many :assignments` — one active per team role at a time
- `CaseTransition` is append-only — never delete transitions
- `RetentionSchedule` is one-to-one with Case::SAR::Offender
- `DataRequestArea has_many :data_requests`; area owns commissioning email
