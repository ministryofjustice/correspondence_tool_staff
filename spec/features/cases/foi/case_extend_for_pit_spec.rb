require "rails_helper"

feature "Applying a PIT extension to a case" do
  given(:manager) { find_or_create :disclosure_bmt_user }
  let(:case_being_drafted) do
    create :case_being_drafted,
           :flagged_accepted, :dacu_disclosure
  end

  background do
    login_as manager
  end

  scenario "manager applies the extension" do
    cases_show_page.load(id: case_being_drafted.id)
    cases_show_page.extend_for_pit_action.click
    expect(cases_extend_for_pit_page).to be_displayed
    cases_extend_for_pit_page.fill_in_extension_date(30.business_days.from_now)
    cases_extend_for_pit_page.reason_for_extending.set "Need a good reason"
    cases_extend_for_pit_page.submit_button.click
    expect(cases_show_page).to be_displayed
    event_row = cases_show_page.case_history.rows.first
    expect(event_row.details.event.text)
      .to eq "Extended for Public Interest Test (PIT)"
  end
end
