require "rails_helper"

RSpec.feature "feedback_link", type: :feature do
  scenario "User clicks the feedback link and sees the feedback page" do
    visit root_path
    expect(page).to have_link("feedback", href: "https://www.smartsurvey.co.uk/s/J38MA6/")

    link = find_link("feedback")
    expect(link[:href]).to include("https://www.smartsurvey.co.uk")
  end
end
