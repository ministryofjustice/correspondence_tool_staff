# 001 — Fixed single SAR deadline extension

**Status:** Accepted
**Date:** 2026-06-17
**Deciders:** CDPTKAN-1081 (Disclosure / Branston product), engineering

## Context

The "Extend SAR deadline" feature previously let a Standard SAR or Offender SAR
be extended by 1 or 2 calendar months, repeatedly, up to a cumulative cap of 2
months (`extension_time_limit: 2`, `extension_time_default: 1`). Product now
wants these case types to be extendable **once, by a fixed 2 months**.

Constraints:

- **SAR Internal Review** uses the same `Extendable` concern (it inherits from
  `Case::SAR::Standard`) and must keep the old multi-extension behaviour.
- The state machine events (`extend_sar_deadline` / `remove_sar_deadline_extension`)
  and case states must not change.
- Cases already extended by 1 month under the old rules must keep that deadline
  and simply lose the ability to extend further.
- The 2-month deadline recalculation already exists and is correct
  (`DeadlineCalculator::CalendarMonths#calculate_final_date_from_time_units`).

## Decision

Drive the behaviour from a new, type-level config flag rather than branching on
case class:

- Add `extension_fixed_period` (integer) to `CorrespondenceType` (jsonb-backed,
  no schema migration). Set it to `2` for SAR and Offender SAR; leave it unset
  for SAR Internal Review.
- `Extendable#deadline_extendable?` branches on `fixed_extension?` (i.e. whether
  `extension_fixed_period` is present):
  - fixed types: extendable only while `!deadline_extended?` (single extension);
  - legacy types: unchanged `months_extended < extension_time_limit`.
- The extension form shows a fixed, non-editable 2-month extension for fixed
  types and keeps the legacy radio/"extend further" UI for Internal Review.
- `CaseExtendSARDeadlineService` validates that fixed types are extended by
  *exactly* `extension_fixed_period`; the submitted period cannot be tampered to
  any other value.
- Retire `extension_time_limit` / `extension_time_default` for SAR and Offender
  SAR (seeder + data migration `20260617120000`); Internal Review keeps them.

Because the gate (`deadline_extendable?`) feeds the state-machine guard, the
Pundit policy, and the show-page link, the single concern change removes the
"Extend deadline" action everywhere once a fixed-type case has been extended —
including legacy 1-month cases — without any per-case data migration.

## Consequences

- **Easier:** divergent behaviour is data-driven and reversible; no state-machine
  or per-case data changes; legacy in-flight 1-month cases degrade gracefully to
  "remove only".
- **Harder / trade-offs:**
  - The extension view now carries two code paths (fixed vs legacy radios).
  - Two config concepts coexist (`extension_fixed_period` for fixed types,
    `extension_time_limit`/`_default` for Internal Review).
  - For fixed types the service's "cannot be before the final deadline" check is
    now largely defensive, since any non-fixed period is rejected first.
  - The data migration must run in every environment for production types to
    pick up `extension_fixed_period`.
