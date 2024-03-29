###################################
#
# ICO FOI case End-to-end User Journey
#
###################################

require "rails_helper"
require Rails.root.join("db/seeders/case_closure_metadata_seeder")

# rubocop:disable RSpec/BeforeAfterAll
feature "ICO FOI case requiring clearance" do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)                { responding_team.responders.first }
  given(:responding_team)          { find_or_create :foi_responding_team }
  given(:disclosure_specialist)    { find_or_create :disclosure_specialist }
  given(:manager)                  { find_or_create :disclosure_bmt_user }
  given!(:team_dacu_disclosure)    { create :team_dacu_disclosure }
  given!(:ico_correspondence_type) { create :ico_correspondence_type }
  given(:original_foi_case)        do
    create :closed_case,
           responder:,
           responding_team:
  end

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  # This test fails at the 'edit case' step when edit_case is fixed to actually do something
  scenario "end-to-end journey", js: true do
    kase = create_and_assign_ico_case user: manager,
                                      responding_team:,
                                      original_case: original_foi_case

    accept_case kase:,
                user: responder,
                do_logout: false

    add_message_to_case kase:,
                        message: "This. Is. A. Test.",
                        do_logout: true

    take_case_on kase:,
                 user: disclosure_specialist,
                 test_undo: true

    upload_response kase:,
                    user: responder,
                    file: UPLOAD_RESPONSE_DOCX_FIXTURE

    edit_case kase:,
              user: manager,
              subject: "new test subject"

    clear_response kase:,
                   user: disclosure_specialist,
                   expected_team: team_dacu_disclosure,
                   expected_status: "Ready to send to ICO",
                   expected_notice: "The response has been cleared and is ready to be sent to the ICO"

    mark_case_as_sent kase:,
                      user: disclosure_specialist,
                      expected_status: "Closed - awaiting ICO decision",
                      expected_to_be_with: "Disclosure"

    close_ico_appeal_case kase:,
                          user: manager,
                          timeliness: "in time",
                          decision: "upheld"
  end
end
# rubocop:enable RSpec/BeforeAfterAll
