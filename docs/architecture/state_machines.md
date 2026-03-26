# State Machines

## Location

```
app/state_machines/configurable_state_machine/
  machine.rb          # Core engine
  manager.rb          # Loads config per case type
  config_validator.rb # Validates machine config

app/state_machines/workflows/
  conditionals.rb     # Guard conditions (predicates for transitions)
  hooks.rb            # before/after transition callbacks
  predicates.rb       # Boolean methods used in conditionals
```

## How It Works

Each case type has a configurable YAML/Ruby-defined state machine. The `Manager` selects the correct machine for a case type. Events are triggered via service objects — never call state transitions directly from controllers.

```ruby
# Correct: via service
CaseClosureService.new(kase, current_user, params).call

# Wrong: direct state call
kase.close!
```

## Common States (FOI/SAR)

```
unassigned → awaiting_responder → drafting → pending_dacu_clearance
→ awaiting_dispatch → responded → closed
```

Offender SAR has a multi-step `drafting` flow with sub-steps tracked by form model.

## Adding a New Transition

1. Define event + guards in the workflow config for the relevant case type
2. Add predicate method to `workflows/predicates.rb` if needed
3. Create/extend a service in `app/services/`
4. Add Pundit permission in the relevant policy
5. Add controller action + route
6. Write RSpec: unit (service), policy, and feature spec

## Stop the Clock / Extensions

- `Stoppable` concern — adds `stop_the_clock` / `restart_the_clock` states
- `Extendable` concern — SAR deadline extension (limit enforced: see `CaseExtendSarDeadlineService`)
- PIT extension — FOI-specific, via `CaseExtendForPitService`
