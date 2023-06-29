require "rails_helper"

feature "add information officer to a business unit" do
  given(:manager) { create :manager }
  given(:bu)      { create :business_unit }

  scenario "case manager adds an information officer to a business unit" do
    bu
    login_as manager

    teams_show_page.load(id: bu.id)
    expect(teams_index_page.heading)
      .to have_text "You are viewing Business unit #{bu.name}"
    teams_show_page.new_information_officer_button.click

    expect(users_new_page).to be_displayed(team_id: bu.id)
    expect(users_new_page.page_heading.sub_heading)
      .to have_text("Business unit: #{bu.name}")

    new_user_name = Faker::Name.name
    new_user_email = Faker::Internet.email(name: new_user_name)
    users_new_page.full_name.set new_user_name
    users_new_page.email.set new_user_email

    users_new_page.submit.click
    expect(teams_show_page).to be_displayed(id: bu.id)
    user_row = teams_show_page.row_for_information_officer(new_user_name)
    expect(user_row.email).to have_text new_user_email
  end
end
