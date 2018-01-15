###################################
#
# Non-Trigger
#
###################################

# SAR NonOffender case is created by factory (until case creation page done)
# KILO accepts case
# KILO uploads response
# KILO marks as response
# Manager view case and closes the case

require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')



feature 'SAR NonOffender case that does not require clearance' do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)       { create :responder }
  given(:responding_team) { responder.responding_teams.first }
  given(:dacu_bmt)        { find_or_create :team_dacu }
  given(:manager)         { create :manager, managing_teams: [ dacu_bmt ] }
  given!(:foi_category)   { create(:category, :foi) }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!(verbose: false)
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'end-to-end journey', js: true do

    kase = create :awaiting_responder_sar,
                  responding_team: responding_team

    edit_case kase: kase,
              user: manager,
              subject: 'new test subject for SAR'

    accept_case kase: kase,
                user: responder,
                do_logout: false


    set_case_dates_back_by(kase, 7.business_days)

    add_message_to_case kase: kase,
                        message: 'This. Is. A. Test.',
                        do_logout: false

    mark_case_as_sent kase: kase,
                      user: responder,
                      do_login: false

    close_case kase: kase,
               user: manager
  end
end
