require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

feature 'Closing a case' do
  given(:kase) { create(:responded_case,
                        received_date: 21.business_days.ago) }

  background do
    kase
    login_as create(:manager)
  end

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  context 'fully granted' do
    before do
      cases_page.load
      expect(cases_page.case_list.last.status.text).to eq 'Ready to close'
      click_link kase.number
      expect(cases_show_page.actions).
        to have_link('Close case', href: close_case_path(kase))
      click_link 'Close case'

      expect(cases_close_page).to have_case_attachments
    end

    scenario 'A KILO has responded and an manager closes the case', js:true do
      cases_close_page.fill_in_date_responded(5.business_days.ago)
      cases_close_page.outcome_radio_button_fully_granted.click
      cases_close_page.submit_button.click

      expect(cases_show_page).to have_no_actions

      show_page = cases_show_page.case_details

      expect(show_page.response_details.date_responded.data.text)
        .to eq 5.business_days.ago.strftime('%e %b %Y').strip
      expect(show_page.response_details.timeliness.data.text)
        .to eq 'Answered in time'
      expect(show_page.response_details.time_taken.data.text)
        .to eq '16 working days'
      expect(show_page.response_details.outcome.data.text)
        .to eq 'Granted in full'
      expect(show_page.response_details).to have_no_refusal_reason
    end

    scenario 'the case is responded-to late', js: true do
      cases_close_page.fill_in_date_responded(
        21.business_days.after(kase.received_date)
      )
      cases_close_page.outcome_radio_button_fully_granted.click
      cases_close_page.submit_button.click

      show_page = cases_show_page.case_details
      expect(show_page.response_details.timeliness.data.text)
        .to eq 'Answered late'
      expect(show_page.response_details.time_taken.data.text)
        .to eq '21 working days'
    end
  end

  context 'Refused fully' do

    before do
      cases_page.load

      expect(cases_page.case_list.last.status.text).to eq 'Ready to close'
      click_link kase.number

      expect(cases_show_page.actions).
          to have_link('Close case', href: close_case_path(kase))
      click_link 'Close case'

      expect(cases_close_page).to have_case_attachments
    end

    scenario 'A KILO has responded and an manager closes the case specifying a refusal reason', js:true do
      expect(cases_close_page).to have_no_refusal
      cases_close_page.fill_in_date_responded(2.business_days.ago)
      cases_close_page.outcome_radio_button_refused_fully.click
      cases_close_page.wait_until_refusal_visible
      cases_close_page.refusal.info_not_held.click
      cases_close_page.submit_button.click

      expect(cases_show_page).to have_content("You've closed this case")
      expect(cases_show_page).to_not have_actions

      show_page = cases_show_page.case_details.response_details

      expect(show_page.date_responded.data.text)
        .to eq 2.business_days.ago.strftime('%e %b %Y').strip
      expect(show_page.timeliness.data.text)
        .to eq 'Answered in time'
      expect(show_page.time_taken.data.text)
        .to eq '19 working days'
      expect(show_page.outcome.data.text)
        .to eq 'Refused fully'
      expect(show_page.refusal_reason.data.text)
        .to eq 'Information not held'
      expect(show_page).to have_no_exemptions
    end


    scenario 'A KILO has responded and an manager closes the case specifying
 a refusal reason and exemption', js:true do
      expect(cases_close_page).to have_no_refusal
      cases_close_page.fill_in_date_responded(2.business_days.ago)

      cases_close_page.outcome_radio_button_refused_fully.click
      cases_close_page.wait_until_refusal_visible

      expect(cases_close_page.refusal).to have_no_exemptions

      cases_close_page.refusal.exemption_applied.click
      cases_close_page.refusal.wait_until_exemptions_visible
      expect(cases_close_page.refusal.exemptions.exemption_options.size).to eq 25

      cases_close_page.refusal.exemptions.exemption_options.first.click
      cases_close_page.refusal.exemptions.exemption_options[2].click

      cases_close_page.submit_button.click

      expect(cases_show_page).to have_content("You've closed this case")
      expect(cases_show_page).to have_no_actions


      show_page = cases_show_page.case_details.response_details

      expect(show_page.date_responded.data.text)
          .to eq 2.business_days.ago.strftime('%e %b %Y').strip
      expect(show_page.timeliness.data.text)
          .to eq 'Answered in time'
      expect(show_page.time_taken.data.text)
          .to eq '19 working days'
      expect(show_page.outcome.data.text)
          .to eq 'Refused fully'
      expect(show_page.refusal_reason.data.text)
          .to eq 'Exemption applied'

      expect(show_page.exemptions)
          .to have_text "Neither confirm nor deny (NCND)"
      expect(show_page.exemptions)
          .to have_text "(s23) - Information supplied by, or relating to, bodies dealing with security matters"
    end
  end

  context 'case refused with an exemption' do
    given(:kase) { create :closed_case, :with_ncnd_exemption }

    scenario 'viewing the response details page' do
      cases_show_page.load(id: kase.id)
      show_page = cases_show_page.case_details.response_details
      expect(show_page.exemptions).to have_text "NCND exemption 1"
    end
  end
end
