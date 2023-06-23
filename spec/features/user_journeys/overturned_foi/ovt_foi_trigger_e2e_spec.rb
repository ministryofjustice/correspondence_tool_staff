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
require Rails.root.join("db/seeders/case_closure_metadata_seeder")

# rubocop:disable RSpec/BeforeAfterAll
feature "FOI case that requires clearance" do
  include Features::Interactions
  include CaseDateManipulation

  given(:responder)             { create :responder }
  given(:responding_team)       { responder.responding_teams.first }
  given(:manager)               { create :manager, managing_teams: [team_dacu] }
  given(:disclosure_specialist) { create :disclosure_specialist }
  given!(:press_officer)        { create :press_officer }
  given(:press_office)          { press_officer.approving_team }
  given(:foi)                   { create :foi_correspondence_type }
  # should only find_or_create default_private_officer - otherwise it causes confusion
  # as having 2 default_private_officer fields can cause strange effects
  given!(:private_officer)      { find_or_create :default_private_officer }
  given(:private_office)        { private_officer.approving_team }
  given!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  given(:team_dacu)             { find_or_create :team_dacu }
  given(:original_appeal_case)  do
    create :closed_ico_foi_case, :overturned_by_ico,
           responding_team:
  end

  background(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  # This scenario fails in the edit step as editing Overturned ICOs hasn't been implemented yet
  xscenario "end-to-end journey", js: true do
    kase = create_and_assign_overturned_ico user: manager,
                                            ico_case: original_appeal_case,
                                            responding_team:,
                                            flag_for_disclosure: true

    take_case_on kase:,
                 user: disclosure_specialist,
                 test_undo: true

    take_case_on kase:,
                 user: press_officer,
                 test_undo: true

    edit_case kase:,
              user: manager,
              subject: "new test subject"

    accept_case kase:,
                user: responder,
                do_logout: false

    set_case_dates_back_by(kase, 5.business_days)

    add_message_to_case kase:, message: "This. Is. A. Test."

    extend_for_pit kase:,
                   user: manager,
                   new_deadline: 30.business_days.from_now

    upload_response kase:,
                    user: responder,
                    file: UPLOAD_RESPONSE_DOCX_FIXTURE

    clear_response kase:,
                   user: disclosure_specialist,
                   expected_team: press_office,
                   expected_status: "Pending clearance",
                   expected_notice: "Press Office has been notified that the response is pending clearance."

    clear_response kase:,
                   user: press_officer,
                   expected_team: private_office,
                   expected_status: "Pending clearance",
                   expected_notice: "Private Office has been notified that the response is pending clearance."

    clear_response kase:,
                   user: private_officer,
                   expected_team: responding_team,
                   expected_status: "Ready to send"

    mark_case_as_sent kase:,
                      user: responder

    close_case kase:,
               user: manager
  end
end
# rubocop:enable RSpec/BeforeAfterAll
