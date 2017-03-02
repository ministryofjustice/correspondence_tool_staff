require 'rails_helper'

feature "Signing in" do
  let(:staff) { create(:user) }

  scenario "Signing in with correct credentials" do
    login_page.load

    expect(login_page).to have_no_user_card

    login_page.log_in(staff.email, staff.password )

    expect(login_page).to have_user_card
    expect(login_page.user_card.greetings).to have_content(staff.email)

    expect(login_page.user_card).to have_link('Sign out', href: destroy_user_session_path)

    expect(login_page).to have_content 'Signed in successfully.'
  end

  scenario "Signing in using invalid email" do
    login_page.load

    login_page.log_in(Faker::Internet.email, staff.password )

    expect(login_page.error_message).to have_content 'Invalid email or password'
  end

  scenario "Signing in using invalid password" do
    login_page.load

    login_page.log_in(staff.email, Faker::Lorem.characters(8) )

    expect(login_page.error_message).to have_content 'Invalid email or password'
  end

end
