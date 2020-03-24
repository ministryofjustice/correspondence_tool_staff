require 'rails_helper'

feature 'joining business units' do

  before(:all) do
    @open_cases = {
      std_draft_foi:              { received_date: 6.business_days.ago },
    }
    @closed_cases = {
      std_closed_foi:  { received_date: 18.business_days.ago },
    }
    @all_cases = @open_cases.merge(@closed_cases)
    @setup = StandardSetup.new(only_cases: @all_cases)
  end

  after(:all) do
    DbHousekeeping.clean
  end

  given(:bu) { find_or_create(:foi_responding_team) }
  given(:manager) { create :manager }
  given(:responder) { find_or_create :foi_responder }

  scenario 'manager joins a business unit to another', js: true do
    # verify responder can see cases before move
    login_as responder
    cases_page.load
    expect(cases_page).to have_text(bu.cases.opened.first.number)
    click_on "Closed cases"
    expect(cases_page).to have_text(bu.cases.closed.first.number)

    # manager moves team
    login_as manager

    teams_show_page.load(id: bu.id)
    teams_show_page.join_team_link.click

    expect(teams_join_page).to be_displayed(id: bu.id)

    select("Operations")

    select("Press Office Directorate")

    teams_join_page.find_row("Press Office").join_team_link.click
byebug
    # teams_move_page.business_groups.links.last.click
    # expect(teams_move_page).to have_content "This is where the team is currently located"

    # teams_move_page.business_groups.links.first.click
    # accept_confirm do
    #   teams_move_page.directorates_list.directorates.first.move_to_directorate_link.click
    # end
    # expect(teams_show_page).to have_content "#{bu.reload.name} has been moved to"

    # # verify responder can see cases after move
    # login_as responder
    # cases_page.load
    # new_bu = BusinessUnit.last
    # expect(cases_page).to have_text(new_bu.cases.opened.first.number)
    # click_on "Closed cases"
    # expect(cases_page).to have_text(bu.reload.cases.closed.first.number)
  end

end
