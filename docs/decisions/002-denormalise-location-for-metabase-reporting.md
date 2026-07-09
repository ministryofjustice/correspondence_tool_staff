# 001 — Denormalise location onto DataRequestArea and DataRequest for Metabase reporting

**Status:** Accepted
**Date:** 2026-07-07
**Deciders:** Mo Seedat

## Context

Since the commissioning redesign (PR #2529), the location of a data request
area has effectively lived on the linked `Contact` record: the new-area form
submits a `contact_id`, and the app displayed the location by reading
`contact.name` through decorators. The `location` columns on
`data_request_areas` and `data_requests` were only populated for legacy
records (pre-redesign free text, copied across by the 2024
`MigrateDataRequestAreas` data migration) and were `NULL` for anything
created through the UI since.

Metabase ingests the `data_requests` and `data_request_areas` tables
directly. Reporting on location therefore required a join to `contacts`, and
questions built on the raw `location` columns showed blanks for all recent
records. We needed the location string to be readable from either table
without querying the related `Contact`, in a way that is consistent and
guaranteed to match what the app displays.

## Decision

Treat `data_request_areas.location` and `data_requests.location` as
denormalised copies of the contact name, maintained by the models on every
write path:

- `DataRequestArea#set_location_from_contact` (`before_validation`) copies
  `contact.name` into `location` on every save whenever a contact is linked,
  overwriting any submitted value. Areas without a contact keep their
  validated free-text location. `location` is now unconditionally required.
- `DataRequestArea#sync_data_request_locations` (`after_update`, on
  `saved_change_to_location?`) pushes location changes down to the area's
  `data_requests` via `update_all`, in the same transaction.
- `DataRequest#set_location_from_data_request_area` (`before_validation`)
  copies the area's location on every save, so new requests are stamped at
  creation. Legacy values are preserved when the area has no location.
- `Contact#sync_denormalised_locations` (`after_update`, on
  `saved_change_to_name?`) updates **both** tables directly when a contact is
  renamed. It must touch `data_requests` itself because its `update_all` on
  areas bypasses the area callback that would otherwise cascade.

Decorators (`DataRequestAreaDecorator#location`,
`DataRequestDecorator#location`) read the denormalised column first and fall
back to the contact name only for records that predate the backfill, so the
app and Metabase read the same value.

### Rake tasks

Three tasks in `lib/tasks/data_request_areas.rake` handle backfill and
reconciliation:

- `rake data_request_areas:backfill_blank_locations` — fills **blank**
  locations only: areas from their contact's name, then data requests from
  their area. Existing values, including legacy free text, are left
  untouched. Run once after deploy to populate historic records.
- `rake data_request_areas:force_sync_locations` — **overwrites** locations
  top-down: all contact-linked areas from the contact name, then all data
  requests from their area (including requests under contact-less free-text
  areas). Idempotent and safe to run at any time; this is the remediation
  tool if drift is ever detected, and the right choice when legacy free-text
  values should be normalised to the current contact name.
- `rake data_request_areas:location_drift_report` — reconciliation check.
  Reports the number of areas whose location differs from their contact's
  name and requests whose location differs from their area's (`IS DISTINCT
  FROM`, so `NULL`s count as drift). Should always report 0/0; a non-zero
  count means something wrote around the model callbacks (`update_column`,
  raw SQL, bulk import) and `force_sync_locations` should be run. Suitable
  for scheduling ahead of Metabase ingests.

## Consequences

- Metabase can report on `location` from either table with no join to
  `contacts`, and the value always matches what the app displays.
- Renaming a contact updates the denormalised values in the same database
  transaction, so the tables can never disagree with the contact record.
- A `location` param submitted alongside a `contact_id` is now ignored in
  favour of the contact's name — the contact is the single source of truth
  for contact-linked records.
- The guarantee holds only for writes that go through Active Record
  callbacks. `update_column`/`update_all`/raw SQL elsewhere can still drift;
  the drift report exists to catch this, and a Postgres trigger was
  deliberately rejected as disproportionate to the risk.
- Two more copies of the same fact exist, so future changes to how locations
  work must consider all three write paths listed above.
- `lib/tasks/list_cases.rake` still exports `dr.location` and `contacts.name`
  as separate columns; after a force sync these are redundant duplicates for
  contact-linked records.
