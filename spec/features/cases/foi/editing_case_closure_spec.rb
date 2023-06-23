require "rails_helper"
require Rails.root.join("db/seeders/case_closure_metadata_seeder")

# rubocop:disable RSpec/BeforeAfterAll
feature "editing case closure information" do
  given(:manager) { find_or_create :disclosure_bmt_user }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario "editing a late closed case", js: true do
    kase = create :closed_case,
                  :late,
                  date_draft_compliant: 11.business_days.ago

    login_as manager
    cases_show_page.load(id: kase.id)
    # find some (non-current) late team ids so the test can change it to another valid one
    possible_late_team_ids = kase.transitions.map(&:acting_team_id).uniq - [kase.late_team_id]
    edit_foi_case_closure_step(kase:,
                               date_responded: 10.business_days.ago,
                               late_team_id: possible_late_team_ids.first)
  end

  scenario "bmt changes case from held/granted to other/tmm", js: true do
    kase = create :closed_case

    login_as manager
    cases_show_page.load(id: kase.id)
    edit_foi_case_closure_step(kase:,
                               date_responded: 10.business_days.ago)
  end

  scenario "bmt edits case that had exemptions", js: true do
    kase = create :closed_case, :fully_refused_exempt_s32

    login_as manager
    cases_show_page.load(id: kase.id)
    edit_foi_case_closure_step(kase:,
                               preselected_exemptions: %w[court],
                               date_responded: 10.business_days.ago,
                               info_held_status: "held",
                               outcome: "granted",
                               refusal_reason: nil)
  end

  scenario "bmt views case details for FOI with old closure info", js: true do
    kase = create :closed_case
    kase.update_attribute(:info_held_status_id, nil) # rubocop:disable Rails/SkipsModelValidations

    login_as manager
    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_details).not_to have_edit_closure
    expect(cases_show_page.case_details)
      .to have_text("This is an old case with closure details that cannot be edited. If you need to edit this case let us know.")
  end

  scenario "responder views case details for FOI with old closure info", js: true do
    kase = create :closed_case
    responder = kase.responder
    kase.update_attribute(:info_held_status_id, nil) # rubocop:disable Rails/SkipsModelValidations

    login_as responder
    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_details).not_to have_edit_closure
    expect(cases_show_page.case_details)
        .not_to have_text("This is an old case with closure details that cannot be edited. If you need to edit this case let us know.")
  end
end
# rubocop:enable RSpec/BeforeAfterAll
