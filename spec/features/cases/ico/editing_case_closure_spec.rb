require "rails_helper"

feature 'editing case closure information' do
  given(:manager) { create :disclosure_bmt_user }

  scenario 'bmt changes ico decision to overturned', js: true do
    kase = create :closed_ico_foi_case

    login_as manager
    cases_show_page.load(id: kase.id)
    edit_ico_case_closure_step(kase: kase,
                               decision_received_date: 10.business_days.ago,
                               ico_decision: 'overturned')
  end

  scenario 'bmt changes ico decision to upheld', js: true do
    kase = create :closed_ico_foi_case, :overturned_by_ico

    login_as manager
    cases_show_page.load(id: kase.id)
    edit_ico_case_closure_step(kase: kase,
                               decision_received_date: 10.business_days.ago,
                               ico_decision: 'upheld')
  end
end
