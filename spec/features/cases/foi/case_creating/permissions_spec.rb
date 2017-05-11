require 'rails_helper'

feature 'Only assigners can create cases' do

  let(:manager)   { create(:manager)   }

  scenario 'As an assigner I can navigate to the New Case form' do
    login_as manager
    cases_page.load
    cases_page.new_case_button.click
    expect(cases_new_page).to be_displayed
  end

end
