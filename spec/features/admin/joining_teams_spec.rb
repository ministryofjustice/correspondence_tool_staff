require "rails_helper"

feature "joining business units" do
  before(:all) do
    @open_cases = {
      std_draft_foi: { received_date: 6.business_days.ago },
    }
    @closed_cases = {
      std_closed_foi: { received_date: 18.business_days.ago },
    }
    @all_cases = @open_cases.merge(@closed_cases)
    @setup = StandardSetup.new(only_cases: @all_cases)
  end

  after(:all) do
    DbHousekeeping.clean(seed: false)
  end

  given(:bu) { find_or_create(:foi_responding_team) }
  given(:manager) { create :manager }
  given(:responder) { find_or_create :foi_responder }
  given!(:target_team) { create(:responding_team, name: "Target Team", directorate: bu.directorate) }
  given!(:deactivated_team) { create(:business_unit, :deactivated, name: "Deactivated Team", directorate: bu.directorate) }

  scenario "manager joins a business unit to another", js: true do
    # verify responder can see cases before move
    login_as responder
    cases_page.load
    open_case_number = bu.cases.opened.first.number
    closed_case_number = bu.cases.closed.first.number
    expect(cases_page).to have_text(open_case_number)
    click_on "Closed cases"
    expect(cases_page).to have_text(closed_case_number)

    # manager loads the bu and starts the join journey
    login_as manager
    teams_show_page.load(id: bu.id)
    teams_show_page.join_team_link.click
    expect(teams_join_page).to be_displayed(id: bu.id)

    # Verify that teams with a special role cannot be joined
    select("Operations")
    select("Press Office Directorate")
    expect(teams_join_page.find_row("Press Office")).not_to have_text "Join with this team"
    expect(teams_join_page.find_row("Press Office")).to have_text "This team has a special role and cannot be joined"

    # Select the correct destination directoraate
    select("Responder Business Group")
    select("Responder Directorate")

    # Deactivated teams should not show up
    expect(teams_join_page.find_row(deactivated_team.name)).to be_nil

    # Join the target team
    teams_join_page.find_row(target_team.name).join_team_link.click
    expect(teams_join_form_page).to be_displayed(id: bu.id)
    teams_join_form_page.join_button.click
    expect(teams_show_page).to be_displayed(id: target_team.id)
    expect(teams_show_page).to have_content "#{bu.original_team_name} has been joined with Target Team"

    # verify responder can see cases after join
    login_as responder
    cases_page.load

    expect(cases_page).to have_text(open_case_number)
    click_on "Closed cases"
    expect(cases_page).to have_text(closed_case_number)
  end
end
