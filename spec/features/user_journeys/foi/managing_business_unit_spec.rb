###################################
#
# CRUD - Business Groups/Directorates/Business Units/Users
#
###################################

# Manager signs in
# Views "Settings" and displays Business Groups
# Drills down into Directorates
# Drills down into Business Units

require "rails_helper"

feature "Viewing Business Groups/Directorate/Business Units" do
  include CaseDateManipulation
  given(:manager)        { create :manager }
  given(:responder)      { find_or_create :foi_responder }
  given(:business_unit) { responder.teams.first }
  given(:business_group) { responder.teams.first.business_group }
  given(:directorate)    { responder.teams.first.directorate }

  background do
    manager
    responder
  end

  scenario "Manager wants to find a specific user" do
    login_as_manager
    visit_settings_page
    view_business_group
    view_directorate
    view_business_unit
    find_information_officer
  end

private

  def login_as_manager
    login_as manager
    open_cases_page.load
  end

  def visit_settings_page
    open_cases_page.primary_navigation.settings.click
    expect(teams_index_page).to be_displayed
  end

  def view_business_group
    teams_index_page.row_for_business_group(business_group.name).name.click
    expect(teams_show_page).to be_displayed

    expect(teams_show_page.heading.text)
        .to eq "You are viewing Business group #{business_group.name}"
  end

  def view_directorate
    row = teams_show_page.row_for_directorate(directorate.name)
    # team_lead = row.director.text

    row.name.click
    expect(teams_show_page).to be_displayed

    expect(teams_show_page.heading.text)
        .to eq "You are viewing Directorate #{directorate.name}"
  end

  def view_business_unit
    teams_show_page.row_for_business_unit(business_unit.name).name.click
    expect(teams_show_page).to be_displayed

    expect(teams_show_page.heading.text)
        .to eq "You are viewing Business unit #{business_unit.name}"
  end

  def find_information_officer
    expect(teams_show_page
               .row_for_information_officer(responder.email)).to be_visible
  end
end
