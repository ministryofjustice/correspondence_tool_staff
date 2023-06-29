require "rails_helper"

feature "Handle partical case", :js do
  given(:responder)         { find_or_create :branston_user }
  given(:offender_sar_case) { create :offender_sar_case }
  given(:closed_offender_sar_case) { create :offender_sar_case, :closed }

  background do
    find_or_create :team_branston
    login_as responder
  end

  scenario "No partial case flags visible for opened case" do
    cases_show_page.load(id: offender_sar_case.id)
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    validate_flags_invisible
  end

  scenario "Update partical cases for closed case" do
    cases_show_page.load(id: closed_offender_sar_case.id)
    expect(cases_show_page).to be_displayed(id: closed_offender_sar_case.id)

    validate_flags_visible
  end

private

  def validate_flags_invisible
    expect(cases_show_page).not_to have_content "Update partial case"
    expect(cases_show_page).not_to have_content "SSCL COVID-19 partial case"
  end

  def validate_flags_visible
    expect(cases_show_page).to have_content "Update partial case"
    expect(cases_show_page).to have_content "SSCL COVID-19 partial case"
  end
end
