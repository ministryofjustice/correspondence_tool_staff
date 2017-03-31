require 'rails_helper'

feature 'Only assigners can create cases' do

  let(:responder) { create(:responder) }
  let(:manager)   { create(:manager)   }

  scenario 'As an assigner I can navigate to the New Case form' do
    login_as manager
    visit cases_path
    expect(page).
      to have_link('New case', href: Rails.root.join(new_case_path))
    click_link "New case"
    expect(page).to have_content 'New case'
    expect(page).to have_button('Continue')
  end

  scenario 'As a responder I cannot navigate to the New Case form' do
    login_as responder
    visit cases_path
    expect(page).
      not_to have_link('New case', href: Rails.root.join(new_case_path))
    visit new_case_path
    expect(page).
      to have_content "You are not authorised to create new cases."
  end

end
