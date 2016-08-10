require 'rails_helper'

feature "Signing in" do

  let(:staff) { create(:user) }

  scenario "Signing in with correct credentials" do
    visit new_user_session_path
    within("#new_user") do
      fill_in 'Email', with: staff.email
      fill_in 'Password', with: staff.password
    end
    click_button 'Sign in'
    expect(page).to have_content 'Signed in successfully.'
  end

  scenario "Signing in using invalid email" do
    visit new_user_session_path
    within("#new_user") do
      fill_in 'Email', with: Faker::Internet.email
      fill_in 'Password', with: staff.password
    end
    click_button 'Sign in'
    expect(page).to have_content 'Invalid email or password'
  end

  scenario "Signing in using invalid password" do
    visit new_user_session_path
    within("#new_user") do
      fill_in 'Email', with: staff.email
      fill_in 'Password', with: Faker::Lorem.characters(8)
    end
    click_button 'Sign in'
    expect(page).to have_content 'Invalid email or password'
  end
end
