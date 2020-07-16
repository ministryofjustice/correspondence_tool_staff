require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

feature 'Closing a case' do
  
  given(:responder)         { find_or_create :branston_user }
  given(:responder_team)   { responder.responding_teams.first }

  background do
    # find_or_create :team_branston
    login_as responder
  end

  context 'Reporting timiliness' do
    Timecop.freeze(Time.local(2017, 11, 23, 13, 13, 56)) do
      context 'responded-to in time' do
        given!(:fully_granted_case) { 
          create :offender_sar_case, 
          :ready_to_dispatch, 
          received_date: 5.business_days.ago }

        scenario 'Offender sar team has responded and a responder closes the case', js:true do
          open_cases_page.load
          close_case(fully_granted_case)

          cases_close_page.fill_in_date_responded(0.business_days.ago)
          cases_close_page.click_on 'Continue'

          expect(cases_closure_outcomes_page).to be_displayed
          expect(cases_closure_outcomes_page).not_to have_content("#{responder_team.name}")

          cases_closure_outcomes_page.submit_button.click

          show_page = cases_show_page.case_details

          expect(show_page.response_details.date_responded.data.text)
          .to eq 0.business_days.ago.strftime(Settings.default_date_format)
          expect(show_page.response_details.timeliness.data.text)
          .to eq 'Answered in time'
          expect(show_page.response_details.time_taken.data.text)
          .to eq '6 working days'
        end
      end

      context 'responded-to late' do
        given!(:fully_granted_case) { 
          create :offender_sar_case,
          :ready_to_dispatch, 
          received_date: 35.business_days.ago }

        scenario 'the case is responded-to late', js: true do
          open_cases_page.load(timeliness: 'late')
          close_case(fully_granted_case)

          cases_close_page.fill_in_date_responded(0.business_days.ago)
          cases_close_page.click_on 'Continue'

          expect(cases_closure_outcomes_page).to be_displayed
          expect(cases_closure_outcomes_page).not_to have_content("#{responder_team.name}")
          cases_closure_outcomes_page.submit_button.click

          show_page = cases_show_page.case_details
          expect(show_page.response_details.timeliness.data.text)
            .to eq 'Answered late'
          expect(show_page.response_details.time_taken.data.text)
            .to eq '36 working days'
        end
      end
    end
  end


  private

  def close_case(kase)
    expect(cases_page.case_list.last.status.text).to eq 'Ready to dispatch'
    click_link kase.number
    expect(cases_show_page.actions).
      to have_link('Close case', href: "/cases/offender_sars/#{kase.id}/close")
    click_link 'Close case'
  end
end
