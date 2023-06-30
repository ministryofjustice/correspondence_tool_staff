require "rails_helper"

feature "deleting SAR cases" do
  given(:manager) { find_or_create :disclosure_bmt_user }

  scenario "deleting an open SAR case" do
    sar_case = create :sar_being_drafted
    login_as manager

    cases_show_page.load(id: sar_case.id)
    delete_case_step(kase: sar_case)
  end

  scenario "deleting a closed SAR case" do
    sar_case = create :closed_sar
    login_as manager

    cases_show_page.load(id: sar_case.id)
    delete_case_step(kase: sar_case)
  end
end
