###################################
#
# Non-Trigger
#
###################################

# Manager creates & assigns to kilo
# KILO accepts case
# KILO uploads response
# KILO marks as response
# Manager view case and closes the case

require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

include CaseDateManipulation

feature "#non-trigger cases" do
  given(:responder)       { create :responder }
  given(:manager)         { create :manager }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!(verbose: false)
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  background do
    manager
    responder
    create(:category, :foi)
  end

  scenario "creating, assigning, responding and closing a case", js: true do
    # Manager creates & assigns to kilo
    login_step user: manager
    kase = create_case_step
    assign_case_step business_unit: responder.responding_teams.first
    kase = set_dates_back_by(kase, 7.days)
    logout_step

    # KILO accepts case, uploads response and marks as sent
    login_step user: responder
    go_to_case_details_step kase: kase
    accept_responder_assignment_step
    upload_response_step file: UPLOAD_RESPONSE_DOCX_FIXTURE
    go_to_case_details_step kase: kase.reload,
                            expected_response_files: ['response.docx']
    mark_case_as_sent_step
    logout_step

    # Manager closes the case
    login_step user: manager
    go_to_case_details_step kase: kase
    close_case_step
  end
end
