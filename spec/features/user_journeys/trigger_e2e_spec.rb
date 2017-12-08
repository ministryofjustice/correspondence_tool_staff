###################################
#
# Trigger
#
###################################

# Manager creates flag case & assigns to kilo team
# KILO accepts case
# KILO uploads response
# DS takes on case
# DS clears case
# KILO marks as response
# Manager view case and closes the case

require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

include CaseDateManipulation

feature "#trigger cases" do
  given(:responder)             { create :responder }
  given(:manager)               { create :manager }
  given(:disclosure_specialist) { create :disclosure_specialist }
  given!(:press_officer)        { create :press_officer }
  given!(:private_officer)      { create :private_officer,
                                         full_name: Settings.private_office_default_user }
  given!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  background do
    manager
    responder
    create(:category, :foi)
  end

  scenario "creating, assigning, responding, approving and closing a case", js: true do
    # Manager creates & assigns to kilo
    login_step user: manager
    kase = create_case_step flag_for_disclosure: true
    assign_case_step business_unit: responder.responding_teams.first
    logout_step

    # Press officer takes case on.
    login_step user: press_officer
    go_to_incoming_cases_step
    take_on_case_step kase: kase
    go_to_incoming_cases_step expect_not_to_see_cases: [kase]
    logout_step

    # Disclosure Specialist takes on a case and approves response
    login_step user: disclosure_specialist
    go_to_incoming_cases_step
    take_on_case_step kase: kase
    go_to_incoming_cases_step expect_not_to_see_cases: [kase]
    logout_step

    # KILO accepts case, uploads response
    login_step user: responder
    go_to_case_details_step kase: kase
    accept_responder_assignment_step

    # Move the case in time so that we can draft it.
    set_case_dates_back_by(kase, 7.days)

    # KILO uploads response
    cases_show_page.load(id: kase.id)
    upload_response_step file: UPLOAD_RESPONSE_DOCX_FIXTURE
    go_to_case_details_step kase: kase.reload,
                            expected_response_files: ['response.docx']
    logout_step

    # Disclosure Specialist approves response
    login_step user: disclosure_specialist
    go_to_case_details_step kase: kase
    approve_case_step kase: kase,
                      expected_team: press_officer.approving_team,
                      expected_status: 'Pending clearance'
    logout_step

    # Press Officer approves response
    login_step user: press_officer
    go_to_case_details_step kase: kase
    approve_case_step kase: kase,
                      expected_team: private_officer.approving_team,
                      expected_status: 'Pending clearance'
    logout_step

    # Private Officer approves response
    login_step user: private_officer
    go_to_case_details_step kase: kase
    approve_case_step kase: kase,
                      expected_team: responder.responding_teams.first,
                      expected_status: 'Ready to send'
    logout_step

    # KILO marks response as sent
    login_step user: responder
    go_to_case_details_step kase: kase
    mark_case_as_sent_step
    logout_step

    # Manager closes the case
    login_step user: manager
    go_to_case_details_step kase: kase
    close_case_step
  end
end
