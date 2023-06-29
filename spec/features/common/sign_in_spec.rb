require "rails_helper"

feature "Signing in" do
  let(:responder)         { find_or_create(:foi_responder) }
  let!(:deactivated_user) { create :deactivated_user }

  scenario "Signing in with correct credentials" do
    login_page.load

    expect(login_page).to have_no_user_card

    login_page.log_in(responder.email, ENV["TESTSPEC_LOGIN_PASSWORD"])

    expect(login_page).to have_user_card
    expect(login_page.user_card.greetings).to have_content(responder.full_name)

    expect(login_page.user_card.has_link?("Sign out", href: destroy_user_session_path)).to eq true
  end

  scenario "Signing in using invalid email" do
    login_page.load

    login_page.log_in(Faker::Internet.email, ENV["TESTSPEC_LOGIN_PASSWORD"])

    expect(login_page.error_message).to have_content "Invalid email or password"
  end

  scenario "Signing in using invalid password" do
    login_page.load

    login_page.log_in(responder.email, Faker::Lorem.characters(number: 8))

    expect(login_page.error_message).to have_content "Invalid email or password"
  end

  scenario "signing in as a deactivated user" do
    login_page.load
    login_page.log_in(deactivated_user.email, ENV["TESTSPEC_LOGIN_PASSWORD"])
    expect(login_page.error_message).to have_content "Invalid email or password."
  end
end
