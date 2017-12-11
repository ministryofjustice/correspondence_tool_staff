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

include CaseDateManipulation
include Features::Interactions


feature 'FOI compliance review case that requires clearance' do
  given(:responder)             { create :responder }
  given(:responding_team)       { responder.responding_teams.first }
  given(:manager)               { create :manager }
  given(:disclosure_specialist) { create :disclosure_specialist }
  given!(:press_officer)        { create :press_officer }
  given(:press_office)          { press_officer.approving_team }
  given!(:private_officer)      { create :private_officer,
                                         full_name: Settings.private_office_default_user }
  given(:private_office)        { private_officer.approving_team }
  given!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  given!(:foi_category)         { create(:category, :foi) }

  background(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'end-to-end journey', js: true do
    kase = create_and_assign_case type: Case::FOI::ComplianceReview,
                                  user: manager,
                                  responding_team: responding_team,
                                  flag_for_disclosure: true

    take_case_on kase: kase,
                 user: disclosure_specialist

    accept_case kase: kase,
                user: responder,
                do_logout: false

    set_case_dates_back_by(kase, 7.days)

    upload_response kase: kase,
                    user: responder,
                    file: UPLOAD_RESPONSE_DOCX_FIXTURE,
                    do_login: false

    clear_response kase: kase,
                   user: disclosure_specialist,
                   expected_team: responding_team,
                   expected_status: 'Ready to send'

    mark_case_as_sent kase: kase,
                      user: responder

    close_case kase: kase,
               user: manager
  end
end
