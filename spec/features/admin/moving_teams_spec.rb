require 'rails_helper'

feature 'moving business units' do

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

  scenario 'manager moves a business unit', js: true do
    login_as manager
    teams_show_page.load(id: bu.directorate.id)
    expect(teams_show_page.row_for_business_unit(bu.name).name.text).to have_text(bu.name)

    # verify manager can see cases before move
    login_as responder
    cases_page.load
    expect(cases_page).to have_text(bu.cases.opened.first.number)
    click_on "Closed cases"
    expect(cases_page).to have_text(bu.cases.closed.first.number)

    login_as manager
    teams_show_page.load(id: bu.id)
    teams_show_page.move_team_link.click
    expect(teams_move_page).to be_displayed(id: bu.id)

    teams_move_page.business_groups.links.last.click

    expect(teams_move_page).to have_content "This is where the team is currently located"

    teams_move_page.business_groups.links.first.click
    accept_confirm do
      teams_move_page.directorates_list.directorates.first.move_to_directorate_link.click
    end

    expect(teams_show_page.flash_notice.text).to eq(
    "#{BusinessUnit.last.name} has been moved to Directorate 1")

    # verify manager can see cases after move
    login_as responder
    cases_page.load
    new_bu = BusinessUnit.last
    expect(cases_page).to have_text(new_bu.cases.opened.first.number)
    click_on "Closed cases"
    expect(cases_page).to have_text(bu.reload.cases.closed.first.number)
  end

end
