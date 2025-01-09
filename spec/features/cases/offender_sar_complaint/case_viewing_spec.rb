require "rails_helper"

feature "Viewing for cases", js: true do
  given(:responding_team)   { create :team_branston }
  given(:responder)         { responding_team.responders.first }

  before do
    set_up_cases
  end

  scenario "View 'My open cases tab' - tab case count numbers are correct" do
    login_as responder

    cases_page.load

    click_link("My open cases")

    expect(page).to have_content("In time (5)")
    expect(page).to have_content("Late (4)")

    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_complaint_type_link.click

    open_cases_page.filter_complaint_type_content.complaint_litigation_checkbox.click
    open_cases_page.case_filters.apply_filters_button.click

    expect(page).to have_content("In time (2)")
    expect(page).to have_content("Late (3)")
  end

  def set_up_cases
    create(:accepted_complaint_case)
    create(:accepted_complaint_case)
    create(:accepted_complaint_case)
    make_case_late(create(:accepted_complaint_case))

    create(:accepted_complaint_case, complaint_type: "litigation_complaint")
    create(:accepted_complaint_case, complaint_type: "litigation_complaint")

    3.times do
      make_case_late(
        create(
          :accepted_complaint_case,
          complaint_type: "litigation_complaint",
        ),
      )
    end
  end

  def make_case_late(kase)
    kase.external_deadline = 5.days.ago
    kase.save!(validate: false)
  end
end
