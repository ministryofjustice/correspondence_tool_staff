require "rails_helper"
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

feature 'editing case closure information' do
  given(:manager) { find_or_create :disclosure_bmt_user }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'bmt changes case closure information', js: true do
    outcome_reasons = [
      CaseClosure::OutcomeReason.first
    ]

    responsible_team = Team.find_by(code: 'DISCLOSURE').id

    kase = create(:closed_sar_internal_review,
                  sar_ir_outcome: 'Upheld in part',
                  team_responsible_for_outcome_id: responsible_team, 
                  outcome_reasons: outcome_reasons)


    login_as manager
    cases_show_page.load(id: kase.id)
    edit_sar_ir_case_closure_step(kase: kase,
                               date_responded: 10.business_days.ago)
  end
end
