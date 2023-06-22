require "rails_helper"
require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")

# rubocop:disable RSpec/BeforeAfterAll
feature "editing case closure information" do
  given(:manager) { find_or_create :disclosure_bmt_user }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario "bmt changes case closure information", js: true do
    kase = create :closed_sar

    login_as manager
    cases_show_page.load(id: kase.id)
    edit_sar_case_closure_step(kase:,
                               date_responded: 10.business_days.ago,
                               tmm: true)
  end
end
# rubocop:enable RSpec/BeforeAfterAll
