require 'rails_helper'

feature "Signing in" do
  given(:page) { LoginPage.new }

  let(:staff) { create(:user) }

  scenario "Signing in with correct credentials" do
    page.load

    expect(page).to have_no_user_card

    page.log_in(staff.email, staff.password )

    expect(page).to have_user_card
    expect(page.user_card.greetings).to have_content(staff.email)

    expect(page.user_card).to have_link('Sign out', href: destroy_user_session_path)

    expect(page).to have_content 'Signed in successfully.'
  end

  scenario "Signing in using invalid email" do
    page.load

    page.log_in(Faker::Internet.email, staff.password )

    expect(page.error_message).to have_content 'Invalid email or password'
  end

  scenario "Signing in using invalid password" do
    page.load

    page.log_in(staff.email, Faker::Lorem.characters(8) )

    expect(page.error_message).to have_content 'Invalid email or password'
  end

end
