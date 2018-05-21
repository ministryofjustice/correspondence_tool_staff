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

    # edit_case kase: kase,
    #           user: manager,
    #           subject: 'new test subject'

    accept_case kase: kase,
                user: responder,
                do_logout: false

    set_case_dates_back_by(kase, 7.business_days)

    add_message_to_case kase: kase,
                        message: 'This. Is. A. Test.',
                        do_logout: false

    click_link 'Close case'

    cases_close_page.fill_in_date_responded(0.business_days.ago)
    cases_close_page.missing_info.no.click

    cases_close_page.submit_button.click

    show_page = cases_show_page.case_details

    expect(show_page.response_details.date_responded.data.text)
      .to eq 0.business_days.ago.strftime(Settings.default_date_format)
    expect(show_page.response_details.timeliness.data.text)
      .to eq 'Answered in time'
    expect(show_page.response_details.time_taken.data.text)
      .to eq '7 working days'
    expect(show_page.response_details).to have_no_refusal_reason
  end
end
