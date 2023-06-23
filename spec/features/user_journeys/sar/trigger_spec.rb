###################################
#
# Non-Offender Trigger SAR End-to-end User Journey
#
###################################

require "rails_helper"
require Rails.root.join("db/seeders/case_closure_metadata_seeder")

# rubocop:disable RSpec/BeforeAfterAll
feature "Non-Offender SAR case requiring clearance" do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)                { responding_team.responders.first }
  given(:responding_team)          { create :sar_responding_team }
  given(:disclosure_specialist)    { find_or_create :disclosure_specialist }
  given(:manager)                  { find_or_create :disclosure_bmt_user }
  given!(:team_dacu_disclosure)    { create :team_dacu_disclosure }
  given!(:sar_correspondence_type) { create :sar_correspondence_type }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario "end-to-end journey", js: true do
    kase = create_and_assign_sar_case user: manager,
                                      responding_team:,
                                      flag_for_disclosure: true
    accept_case kase:,
                user: responder,
                do_logout: false

    add_message_to_case kase:,
                        message: "This. Is. A. Test.",
                        do_logout: true

    take_case_on kase:,
                 user: disclosure_specialist,
                 test_undo: true

    progress_to_disclosure_step kase:,
                                user: responder,
                                do_logout: true

    clear_response kase:,
                   user: disclosure_specialist,
                   expected_team: responding_team,
                   expected_status: "Ready to send"

    close_sar_case kase:,
                   user: responder,
                   timeliness: "in time"
  end
end
# rubocop:enable RSpec/BeforeAfterAll
