require "rails_helper"

feature "editing case closure information" do
  given(:manager) { find_or_create :disclosure_bmt_user }

  context "when case is a FOI" do
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

    scenario "cannot see complaint outcome" do
      Timecop.freeze(11.business_days.ago) do
        kase = create :closed_ico_foi_case
        Timecop.return
        login_as manager
        cases_show_page.load(id: kase.id)
        expect(cases_show_page).to be_displayed(id: kase.id)
        expect(cases_show_page.case_details).to have_edit_closure
        cases_show_page.case_details.edit_closure.click
        expect(cases_edit_closure_page).not_to have_content("What was the outcome of the SAR complaint?")
      end
    end
  end

  context "when case is a SAR", js: true do
    scenario "change ico decision" do
      kase = create :closed_ico_sar_case, :overturned_by_ico, created_at: 11.business_days.ago
      Timecop.return
      login_as manager
      cases_show_page.load(id: kase.id)
      edit_ico_case_closure_step(kase:,
                                 decision_received_date: 10.business_days.ago,
                                 ico_decision: "upheld")
    end

    scenario "change complaint outcome" do
      kase = create :closed_ico_sar_case, :overturned_by_ico, created_at: 11.business_days.ago
      Timecop.return
      login_as manager
      cases_show_page.load(id: kase.id)
      edit_ico_case_closure_step(kase:,
                                 decision_received_date: 10.business_days.ago,
                                 ico_complaint_outcome: "sar_processed_but_overdue")
    end

    scenario "change complaint outcome to other" do
      kase = create :closed_ico_sar_case, :overturned_by_ico, created_at: 11.business_days.ago
      Timecop.return
      login_as manager
      cases_show_page.load(id: kase.id)
      edit_ico_case_closure_step(kase:,
                                 decision_received_date: 10.business_days.ago,
                                 ico_complaint_outcome: "other_outcome")
    end
  end
end
