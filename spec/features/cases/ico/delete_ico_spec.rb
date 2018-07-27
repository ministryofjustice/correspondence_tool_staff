require "rails_helper"

feature 'deleting ICO cases' do

  given(:manager) { create :disclosure_bmt_user }

  scenario 'deleting an open SAR case' do
    accepted_ico_foi_case = create :accepted_ico_foi_case
    login_as manager

    cases_show_page.load(id: accepted_ico_foi_case.id)
    delete_case_step(kase: accepted_ico_foi_case)
  end
end
