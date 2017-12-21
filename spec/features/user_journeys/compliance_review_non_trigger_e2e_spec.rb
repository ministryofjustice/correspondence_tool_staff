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

feature 'FOI compliance review case that does not require clearance' do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)       { create :responder }
  given(:responding_team) { responder.responding_teams.first }
  given(:manager)         { create :manager }
  given!(:foi_category)   { create(:category, :foi) }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!(verbose: false)
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'end-to-end journey', js: true do
    kase = create_and_assign_case type: Case::FOI::ComplianceReview,
                                  user: manager,
                                  responding_team: responding_team

    edit_case kase: kase,
              user: manager,
              subject: 'new test subject'

    accept_case kase: kase,
                user: responder,
                do_logout: false

    set_case_dates_back_by(kase, 5.business_days)

    add_message_to_case kase: kase,
                        message: 'This. Is. A. Test.',
                        do_logout: false

    upload_response kase: kase,
                    user: responder,
                    file: UPLOAD_RESPONSE_DOCX_FIXTURE,
                    do_login: false

    mark_case_as_sent kase: kase,
                      user: responder

    close_case kase: kase,
               user: manager
  end
end
