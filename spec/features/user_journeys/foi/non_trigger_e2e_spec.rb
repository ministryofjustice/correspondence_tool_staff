###################################
#
# Standard FOI Non-Trigger End-to-end User Journey
#
###################################

# Manager creates & assigns to kilo
# KILO accepts case
# KILO uploads response
# KILO marks as response
# Manager view case and closes the case

require "rails_helper"
require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")

# rubocop:disable RSpec/BeforeAfterAll
feature "FOI case that does not require clearance" do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)       { responding_team.responders.first }
  given(:responding_team) { find_or_create :foi_responding_team }
  given(:manager)         { find_or_create :disclosure_bmt_user }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario "end-to-end journey", js: true do
    kase = create_and_assign_foi_case(type: Case::FOI::Standard,
                                      user: manager,
                                      responding_team:)

    edit_case kase:,
              user: manager,
              subject: "new test subject"

    accept_case kase:,
                user: responder,
                do_logout: false

    set_case_dates_back_by(kase, 7.business_days)

    add_message_to_case kase:,
                        message: "This. Is. A. Test.",
                        do_logout: false

    upload_response kase:,
                    user: responder,
                    file: UPLOAD_RESPONSE_DOCX_FIXTURE,
                    do_login: false

    mark_case_as_sent kase:,
                      user: responder

    close_case kase:,
               user: manager
  end
end
# rubocop:enable RSpec/BeforeAfterAll
