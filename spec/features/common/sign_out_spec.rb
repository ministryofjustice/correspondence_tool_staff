require "rails_helper"

feature "Signing Out" do
  scenario "Signing out from login page" do
    login_page.load

    expect(login_page).to have_no_user_card
  end

  scenario "Signed in and need to sign out" do
    login_as find_or_create(:foi_responder)

    cases_page.load

    expect(cases_page).to have_user_card

    cases_page.user_card.signout.click

    expect(page).to have_content("Signed out successfully.")
  end
end
