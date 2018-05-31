###################################
#
# Non-Offender Non-Trigger SAR End-to-end User Journey
#
###################################


require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')


feature 'Non-Offender SAR case that does not require clearance' do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)                { create :responder }
  given(:responding_team)          { responder.responding_teams.first }
  given(:manager)                  { create :disclosure_bmt_user }
  given!(:sar_correspondence_type) { create :sar_correspondence_type }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!(verbose: false)
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'end-to-end journey', js: true do
    kase = create_and_assign_sar_case user: manager,
                                      responding_team: responding_team
    accept_case kase: kase,
                user: responder,
                do_logout: false

    set_case_dates_back_by(kase, 7.business_days)

    add_message_to_case kase: kase,
                        message: 'This. Is. A. Test.',
                        do_logout: false

    close_sar_case timeliness: 'in time'
  end
end
