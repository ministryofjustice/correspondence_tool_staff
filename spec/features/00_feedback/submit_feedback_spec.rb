require 'rails_helper'

feature "Submitting feedback" do
  given(:login_page) { LoginPage.new }
  given(:home_page) { CaseListPage.new }
  let(:user) { create(:user) }

  scenario "Cannot submit feedback from login page" do
    login_page.load
    expect(login_page).to have_no_service_feedback
  end

  scenario "user signed in and wants to submit feedback without comment", js: true do

    login_as user
    home_page.load
    expect(home_page).to have_service_feedback
    expect(home_page.service_feedback).to have_feedback_form
    expect(home_page.service_feedback).to have_send_button

    home_page.service_feedback.feedback_textarea.set ""
    home_page.service_feedback.send_button.click

    home_page.service_feedback.wait_for_error_notice
    expect(home_page.service_feedback).to have_error_notice
  end

  scenario "user signed in and wants to submit feedback", js: true do


    login_as user
    home_page.load

    expect(home_page).to have_service_feedback
    expect(home_page.service_feedback).to have_feedback_form
    expect(home_page.service_feedback).to have_send_button

    home_page.service_feedback.feedback_textarea.set "Very good service"
    home_page.service_feedback.send_button.click

    home_page.service_feedback.wait_for_success_notice
    expect(home_page.service_feedback).to have_success_notice
    expect(home_page.service_feedback.feedback_textarea.text).to eq ""
    expect(Feedback.first.comment).to eq "Very good service"
    expect(Feedback.first.email).to eq user.email

  end
end
