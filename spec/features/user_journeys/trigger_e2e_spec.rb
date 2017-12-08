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
  given(:responder)       { create :responder }
  given(:manager)         { create :manager }
  given(:disclosure_specialist) { create :disclosure_specialist }
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
    kase = set_dates_back_by(kase, 7.days)
    logout_step

    # KILO accepts case, uploads response
    login_step user: responder
    go_to_case_details_step kase: kase
    accept_responder_assignment_step
    upload_response_step file: UPLOAD_RESPONSE_DOCX_FIXTURE
    go_to_case_details_step kase: kase.reload,
                            expected_response_files: ['response.docx']
    logout_step

    # DACU DS takes on a case and approves response
    login_step user: disclosure_specialist
    go_to_incoming_cases_step
    take_on_case_step kase: kase
    go_to_case_details_step page: incoming_cases_page,
                            kase: kase
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
