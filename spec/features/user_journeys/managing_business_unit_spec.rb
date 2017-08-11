###################################
#
# CRUD - Business Groups/Directorates/Business Units/Users
#
###################################

# Manager signs in
# Views "Settings" and displays Business Groups
# Drills down into Directorates
# Drills down into Business Units


require 'rails_helper'

include CaseDateManipulation

feature "Viewing Business Groups/Directorate/Business Units" do
  given(:manager)         { create :manager }
  given(:responder)       { create :responder }

  background do
    manager
  end

  fscenario 'Manager wants to find a specific user' do
    login_as_manager
    visit_settings_page

  end


  private


  def login_as_manager
    login_as manager

    open_cases_page.load(timeliness: 'in-time')
  end

  def visit_settings_page
    open_cases_page.primary_navigation.settings.click
    expect(teams_index)
  end
end
