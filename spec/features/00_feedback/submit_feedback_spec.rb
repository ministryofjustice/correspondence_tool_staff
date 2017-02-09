require 'rails_helper'

feature "Submitting feedback" do
  given(:login_page) { LoginPage.new }
  given(:home_page) { CaseListPage.new }

  scenario "Cannot submit feedback from login page" do
    login_page.load
    expect(login_page).to have_no_service_feedback
  end

  scenario "user signed in and wants to submit feedback" do

    login_as create(:user)
    home_page.load

    expect(home_page).to have_service_feedback
    expect(home_page.service_feedback).to have_feedback_form
    expect(home_page.service_feedback).to have_send_button

    home_page.service_feedback.send_feedback "Very good service"



  end


end
