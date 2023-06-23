###################################
#
# Non-Offender Trigger overturned SAR End-to-end User Journey
#
###################################

require "rails_helper"
require Rails.root.join("db/seeders/case_closure_metadata_seeder")

# rubocop:disable RSpec/BeforeAfterAll
feature "Overturned non-Offender SAR case requiring clearance" do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)                           { create :responder }
  given(:responding_team)                     { responder.responding_teams.first }
  given(:disclosure_specialist)               { create :disclosure_specialist }
  given(:manager)                             { create :disclosure_bmt_user }
  given!(:team_dacu_disclosure)               { find_or_create :team_dacu_disclosure }
  given!(:overturned_sar_correspondence_type) { create :overturned_sar_correspondence_type }
  given(:original_appeal_case)                do
    create :closed_ico_sar_case,
           :overturned_by_ico,
           responding_team:
  end

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  # @todo: Test disable as is overturned FOI - requires revision
  xscenario "end-to-end journey", js: true do
    kase = create_and_assign_overturned_ico user: manager,
                                            responding_team:,
                                            ico_case: original_appeal_case,
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
