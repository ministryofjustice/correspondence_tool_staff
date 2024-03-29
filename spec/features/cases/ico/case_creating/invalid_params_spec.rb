require "rails_helper"

feature "creating ICO with invalid params" do
  given(:manager) { find_or_create :disclosure_bmt_user }
  given!(:original_foi) { create :closed_case }

  background do
    login_as manager
  end

  scenario "setting draft deadline before external", js: true do
    cases_new_ico_page.load
    cases_new_ico_page.form.fill_in_case_details(
      received_date: 0.business_days.ago,
      internal_deadline: 20.business_days.from_now,
      external_deadline: 10.business_days.from_now,
      uploaded_request_files: [],
    )
    cases_new_ico_page.form.add_original_case(original_foi)

    click_button "Create case"

    expect(page).to have_current_path "/cases/icos"
    expect(cases_new_ico_page.errors.details.count).to eq 1
    expect(cases_new_ico_page.errors.details.first)
      .to have_content("Draft deadline cannot be after final deadline")
  end

  scenario "creating case with no data entry", js: true do
    cases_new_ico_page.load

    click_button "Create case"

    expect(cases_new_ico_page.errors.details.count).to eq 7
  end
end
