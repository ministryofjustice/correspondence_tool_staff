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
          create :offender_sar_complaint,
          :response_required,
          received_date: 5.days.ago }

        scenario 'Offender sar team has responded and a responder closes the case', js:true do
          open_cases_page.load
          close_case(fully_granted_case)

          expect(cases_close_page).to have_link('Back', href: "/cases/#{fully_granted_case.id}")
          cases_close_page.fill_in_date_responded(0.days.ago)
          cases_close_page.click_on 'Continue'

          expect(cases_closure_outcomes_page).not_to be_displayed

          show_page = cases_show_page.case_details

          expect(show_page.response_details.date_responded.data.text)
          .to eq 0.days.ago.strftime(Settings.default_date_format)
          expect(show_page.response_details.timeliness.data.text)
          .to eq 'Answered in time'
          expect(show_page.response_details.time_taken.data.text)
          .to eq '5 calendar days'
        end
      end

      context 'responded-to late' do
        given!(:fully_granted_case) {
          create :offender_sar_complaint,
          :response_required,
          received_date: 35.days.ago }

        scenario 'the case is responded-to late', js: true do
          fully_granted_case.external_deadline = 30.days.ago
          fully_granted_case.save!
          open_cases_page.load(timeliness: 'late')
          close_case(fully_granted_case)

          expect(cases_close_page).to have_link('Back', href: "/cases/#{fully_granted_case.id}")
          cases_close_page.fill_in_date_responded(0.days.ago)
          cases_close_page.click_on 'Continue'

          expect(cases_closure_outcomes_page).not_to be_displayed

          show_page = cases_show_page.case_details

          expect(show_page.response_details.timeliness.data.text)
            .to eq 'Answered late'
          expect(show_page.response_details.time_taken.data.text)
            .to eq '35 calendar days'
        end
      end
    end
  end


  private

  def close_case(kase)
    expect(cases_page.case_list.last.status.text).to eq 'Response is required'
    click_link kase.number
    expect(cases_show_page.actions).
      to have_link('Close case', href: "/cases/offender_sar_complaints/#{kase.id}/close")
    click_link 'Close case'
  end
end
