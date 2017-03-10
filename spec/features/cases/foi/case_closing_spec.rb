require 'rails_helper'
require File.join(Rails.root, 'db', 'case_closure_metadata_seeder')

feature 'Closing a case' do
  given(:kase)        { create(:responded_case) }

  background do
    kase
    login_as create(:assigner)
  end

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end


  context 'fully granted' do
    scenario 'A KILO has responded and an assigner closes the case', js:true do
      visit cases_path
      expect(cases_page.case_list.last.status.text).to eq 'Waiting to be closed'
      click_link kase.number

      expect(cases_show_page.sidebar.actions).
        to have_link('Close case', href: close_case_path(kase))
      click_link 'Close case'

      expect(cases_close_page).to have_content("Close case")
      cases_close_page.fill_in_date_responded(2.days.ago)
      cases_close_page.outcome_radio_button_fully_granted.click
      cases_close_page.submit_button.click

      expect(cases_show_page).to have_content("You've closed this case")
      expect(cases_show_page.sidebar.status.text).to eq 'Case closed'
      expect(cases_show_page.sidebar.actions).not_to have_link('Close case')
      expect(cases_show_page.sidebar.actions.text).to eq 'No actions available'
    end
  end

  context 'Refused fully' do
    scenario 'A KILO has responded and an assigner closes the case specifying a refusal reason', js:true do
      visit cases_path
      expect(cases_page.case_list.last.status.text).to eq 'Waiting to be closed'
      click_link kase.number

      expect(cases_show_page.sidebar.actions).
        to have_link('Close case', href: close_case_path(kase))
      click_link 'Close case'

      expect(cases_close_page).to have_content("Close case")
      cases_close_page.fill_in_date_responded(2.days.ago)
      cases_close_page.outcome_radio_button_refused_fully.click
      cases_close_page.refusal_reason_button_info_not_held.click
      cases_close_page.submit_button.click

      expect(cases_show_page).to have_content("You've closed this case")
      expect(cases_show_page.sidebar.status.text).to eq 'Case closed'
      expect(cases_show_page.sidebar.actions).not_to have_link('Close case')
      expect(cases_show_page.sidebar.actions.text).to eq 'No actions available'
    end
  end


end
