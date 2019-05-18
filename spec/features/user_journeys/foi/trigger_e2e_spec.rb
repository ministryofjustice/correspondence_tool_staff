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

require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

feature 'FOI case that does not require clearance' do
  include Features::Interactions
  include CaseDateManipulation

  given(:responder)             { responding_team.responders.first }
  given(:responding_team)       { find_or_create :foi_responding_team }
  given(:manager)               { find_or_create :disclosure_bmt_user }
  given(:disclosure_specialist) { find_or_create :disclosure_specialist }
  given!(:press_officer)        { press_office.approvers.first }
  given(:press_office)          { find_or_create :team_press_office }
  given(:foi)                   { find_or_create :foi_correspondence_type }
  given!(:private_officer)      { find_or_create :default_private_officer }
  given(:private_office)        { find_or_create :team_private_office }
  given!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  given(:team_dacu)             { find_or_create :team_dacu }

  background(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'end-to-end journey', js: true do
    kase = create_and_assign_foi_case type: Case::FOI::Standard,
                                  user: manager,
                                  responding_team: responding_team,
                                  flag_for_disclosure: true

    take_case_on kase: kase,
                 user: disclosure_specialist,
                 test_undo: true
    take_case_on kase: kase,
                 user: press_officer,
                 test_undo: true

    edit_case kase: kase,
              user: manager,
              subject: 'new test subject'

    accept_case kase: kase,
                user: responder,
                do_logout: false

    set_case_dates_back_by(kase, 5.business_days)

    add_message_to_case kase: kase, message: 'This. Is. A. Test.'

    extend_for_pit kase: kase,
                   user: manager,
                   new_deadline: 30.business_days.from_now

    upload_response kase: kase,
                    user: responder,
                    file: UPLOAD_RESPONSE_DOCX_FIXTURE

    clear_response kase: kase,
                   user: disclosure_specialist,
                   expected_team: press_office,
                   expected_status: 'Pending clearance',
                   expected_notice: 'Press Office has been notified that the response is pending clearance.'

    clear_response kase: kase,
                   user: press_officer,
                   expected_team: private_office,
                   expected_status: 'Pending clearance',
                   expected_notice: 'Private Office has been notified that the response is pending clearance.'

    clear_response kase: kase,
                   user: private_officer,
                   expected_team: responding_team,
                   expected_status: 'Ready to send'

    mark_case_as_sent kase: kase,
                      user: responder

    close_case kase: kase,
               user: manager
  end
end
