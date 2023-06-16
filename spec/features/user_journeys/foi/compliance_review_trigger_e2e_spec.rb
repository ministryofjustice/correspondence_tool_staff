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

require "rails_helper"
require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")

feature "FOI compliance review case that requires clearance" do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)             { responding_team.responders.first }
  given(:responding_team)       { find_or_create :foi_responding_team }
  given(:team_dacu)             { create :team_dacu }
  given(:manager)               { find_or_create :disclosure_bmt_user }
  given(:disclosure_specialist) { find_or_create :disclosure_specialist }
  given!(:press_officer)        { press_office.approvers.first }
  given(:press_office)          { create :team_press_office }
  given(:foi)                   { create :foi_correspondence_type }
  given!(:private_officer)      { private_office.approvers.first }
  given(:private_office)        { create :team_private_office }
  given!(:team_dacu_disclosure) { create :team_dacu_disclosure }

  background(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario "end-to-end journey", js: true do
    kase = create_and_assign_foi_case type: Case::FOI::ComplianceReview,
                                      user: manager,
                                      responding_team:,
                                      flag_for_disclosure: true

    take_case_on kase:,
                 user: disclosure_specialist,
                 test_undo: true

    edit_case kase:,
              user: manager,
              subject: "new test subject"

    accept_case kase:,
                user: responder,
                do_logout: false

    set_case_dates_back_by(kase, 5.business_days)

    add_message_to_case kase:,
                        message: "This. Is. A. Test."

    extend_for_pit kase:,
                   user: manager,
                   new_deadline: 30.business_days.from_now

    upload_response kase:,
                    user: responder,
                    file: UPLOAD_RESPONSE_DOCX_FIXTURE

    clear_response kase:,
                   user: disclosure_specialist,
                   expected_team: responding_team,
                   expected_status: "Ready to send"

    mark_case_as_sent kase:,
                      user: responder

    close_case kase:,
               user: manager
  end
end
