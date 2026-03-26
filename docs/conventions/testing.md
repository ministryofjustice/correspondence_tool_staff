# Testing Conventions

## Stack

- **RSpec** — unit, request, feature specs
- **Capybara + ChromeDriver** — JS feature tests (tagged `js: true`)
- **FactoryBot** — `spec/factories/`
- **parallel_tests** — full suite runs on 8 CPUs

## Running Tests

```bash
# Single file
bundle exec rspec spec/services/case_create_service_spec.rb

# Directory
bundle exec rspec spec/services/

# With docs format
bundle exec rspec --format documentation spec/path/

# Full suite (parallel)
bundle exec parallel_rspec spec/

# Feature specs only
bundle exec rspec spec/features/
```

## Spec Structure

```
spec/
├── features/          # Capybara end-to-end
├── services/          # Service object unit tests
├── models/            # Model unit tests
├── policies/          # Pundit policy tests
├── controllers/       # Controller specs (use request specs for new)
├── decorators/
├── mailers/
├── jobs/
├── factories/         # FactoryBot definitions
└── support/           # Shared contexts, helpers, matchers
```

## Key Factory Conventions

```ruby
# Case factories mirror model namespace
FactoryBot.create(:foi_case)                    # Case::FOI::Standard
FactoryBot.create(:offender_sar_case)
FactoryBot.create(:offender_sar_complaint_case)

# User roles
FactoryBot.create(:manager)
FactoryBot.create(:responder)
FactoryBot.create(:approver)
```

## Testing Services

```ruby
describe CaseCreateService do
  subject(:service) { described_class.new(user, kase, params) }

  it "transitions state" do
    expect { service.call }.to change { kase.current_state }
  end
end
```

## Shared Contexts

Common Pundit helpers in `spec/support/`. Use `sign_in` helper for authentication in feature specs.

## CI

GitHub Actions runs: `bundle exec parallel_rspec spec/` — ensure new specs pass locally before pushing.
