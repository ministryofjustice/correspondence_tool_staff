require "rails_helper"

feature "editing case closure information" do
  given(:manager) { find_or_create :disclosure_bmt_user }

  scenario "bmt changes ico decision to overturned", js: true do
    Timecop.freeze(11.business_days.ago) do
      kase = create :closed_ico_foi_case
      Timecop.return
      login_as manager
      cases_show_page.load(id: kase.id)
      edit_ico_case_closure_step(kase:,
                                 decision_received_date: 10.business_days.ago,
                                 ico_decision: "overturned")
    end
  end

  scenario "bmt changes ico decision to upheld", js: true do
    Timecop.freeze(11.business_days.ago) do
      kase = create :closed_ico_foi_case, :overturned_by_ico, created_at: 11.business_days.ago
      Timecop.return
      login_as manager
      cases_show_page.load(id: kase.id)
      edit_ico_case_closure_step(kase:,
                                 decision_received_date: 10.business_days.ago,
                                 ico_decision: "upheld")
    end
  end
end
