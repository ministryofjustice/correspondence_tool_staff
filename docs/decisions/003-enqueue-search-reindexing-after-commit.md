# 003 — Enqueue search reindexing after commit, with a dirty-case sweeper

**Status:** Accepted
**Date:** 2026-07-09
**Deciders:** Mo Seedat

## Context

Case full-text search runs against `cases.document_tsvector`, which is an
`ignored_column` as far as Active Record is concerned. The only writer is
`Searchable#update_index`, executed asynchronously by
`SearchIndexUpdaterJob` (Sidekiq): the job reloads the case from the
database, rebuilds the weighted tsvector from
`searchable_fields_and_ranks`, and clears the `dirty` flag.

Previously the job was enqueued from a `before_save` callback
(`trigger_reindexing`) and an `after_create` callback, i.e. **while the
surrounding database transaction was still open**. On Rails 8 with Sidekiq
and no `enqueue_after_transaction_commit` configured, `perform_later`
pushes to Redis immediately, so the job could start before the transaction
committed and index the case's *pre-commit* state.

This surfaced as Offender SAR case numbers missing from the search index.
Offender SAR is the only case type whose `number` can change after
creation: validating a rejected case
(`CaseValidateRejectedOffenderSARService`) replaces the `R`-prefixed
number with a newly issued one, inside an `ActiveRecord::Base.transaction`
that also runs the state machine transition. When the reindex job raced
the commit it indexed the old `R` number; because tsquery prefix matching
is left-anchored, searching for the case's real number then found nothing.
The failure was silent and permanent: the job ran "successfully", the
pre-commit snapshot it read still had `dirty = false` so the flag it left
behind was inconsistent, and nothing ever reindexed dirty cases.

Two compounding gaps:

- On creation the `dirty` flag was never set at all, so a lost creation
  job (Redis flush, pod killed mid-deploy) left a case unfindable with no
  marker that anything was wrong.
- There was no reconciliation mechanism — `dirty = true` was written by
  updates but nothing swept it.

## Decision

Split "record that a case needs reindexing" from "enqueue the reindex",
and put each on the correct side of the transaction boundary
(`app/models/case/base.rb`):

- `before_save :mark_for_reindexing` persists `dirty = true` **inside the
  same transaction** as the change, whenever the record is new or a field
  in `indexable_fields` changed. The flag now also marks freshly created,
  not-yet-indexed cases.
- `after_commit :trigger_reindexing, on: %i[create update]` enqueues
  `SearchIndexUpdaterJob` only once the data the job will read is
  committed, and only when the case is dirty. This replaces both the
  `before_save` enqueue and the separate `trigger_reindexing_after_creation`
  callback. `after_commit` fires once per record per transaction, so a
  service that saves the case several times enqueues one job.

The `dirty` flag therefore has a precise meaning: *the committed row may
not match the search index*. The job clears it (`mark_as_clean`,
`update_column`, so no callback loop) after rebuilding the tsvector.

As a safety net for jobs that are enqueued but never run, a new rake task
`search:reindex_dirty_cases` (`lib/tasks/search.rake`) re-enqueues
indexing for every case still flagged dirty. It runs hourly via a
Kubernetes CronJob in each environment
(`config/kubernetes/*/cronjob-reindex-dirty-cases.yaml`, wired into
`.github/workflows/deploy.yml` alongside the existing case cronjobs).

Alternatives considered:

- `config.active_job.enqueue_after_transaction_commit = :always` — fixes
  the race globally but changes enqueue semantics for *every* job in the
  app; rejected as disproportionate when only reindexing reads its own
  row back.
- A Postgres trigger maintaining the tsvector synchronously — would remove
  the async gap entirely, but moves the field list and weighting into SQL,
  duplicating `searchable_fields_and_ranks` (which subclasses override)
  outside Ruby.

## Consequences

- Reindex jobs can no longer observe pre-commit state; the validated
  rejected Offender SAR number is indexed correctly.
- A save that rolls back no longer enqueues a reindex at all (previously
  it did, harmlessly but wastefully).
- A freshly created case is `dirty` until its index job runs. Specs that
  asserted "clean after create" were updated; the `:clean` factory trait
  gives a clean case where tests need one.
- Any lost or failed reindex job now self-heals within an hour via the
  sweeper, for creates as well as updates.
- The guarantee only covers writes that run Active Record save callbacks.
  `update_column`/`update_all`/raw SQL paths neither set the flag nor
  enqueue; the existing `Assignment` path relies on its own
  `mark_as_dirty` + delayed enqueue and is unchanged.
- Historic cases whose index went stale *before* this change and whose
  `dirty` flag is `false` are not picked up by the sweeper; a one-off
  `Case::Base.update_all_indexes` is needed to repair them.
