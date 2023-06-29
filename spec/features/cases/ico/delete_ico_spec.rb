require "rails_helper"

feature "deleting ICO cases" do
  given(:manager) { find_or_create :disclosure_bmt_user }

  scenario "deleting an open ICO case" do
    accepted_ico_foi_case = create :accepted_ico_foi_case
    linked_foi_case = accepted_ico_foi_case.linked_cases.first
    login_as manager

    cases_show_page.load(id: accepted_ico_foi_case.id)
    delete_case_step(kase: accepted_ico_foi_case)
    expect(linked_foi_case.linked_cases).to eq []
  end
end
