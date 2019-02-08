require "rails_helper"

feature 'extending a SAR case deadline' do
  given(:manager)   { find_or_create :disclosure_bmt_user }
  given(:approver)  { create :disclosure_specialist }
  given(:responder) { kase.responder }
  given!(:kase)     { create :accepted_sar }

  context 'a manager' do
    scenario 'extending a SAR case by 30 days twice' do
      original_final_deadline = kase.external_deadline.clone
      expected_final_date = (original_final_deadline + 60.days).strftime('%-d %b %Y')

      login_as manager
      cases_show_page.load(id: kase.id)

      cases_show_page.actions.extend_sar_deadline.click
      expect(cases_extend_sar_deadline_page).to be_displayed

      cases_extend_sar_deadline_page.extension_period_30_days.click
      cases_extend_sar_deadline_page.set_reason_for_extending('A manager wants to extend')
      cases_extend_sar_deadline_page.submit_button.click

      expected_case_history = [
        'Extended SAR deadline',
        'A manager wants to extend',
        ' Deadline extended by 30 days'
      ]

      expect(cases_show_page).to be_displayed
      expect(cases_show_page.notice.text).to eq 'Case extended for SAR'
      expect(cases_show_page.case_history.rows.first.details.text).to eq(expected_case_history.join)


      cases_show_page.actions.extend_sar_deadline.click
      expect(cases_extend_sar_deadline_page).not_to have_extension_period_30_days
      expect(cases_extend_sar_deadline_page).to have_text('The deadline for this case will be extended by a further 30 days.')
      cases_extend_sar_deadline_page.set_reason_for_extending('Require even more time')
      cases_extend_sar_deadline_page.submit_button.click

      expected_case_history = [
        'Extended SAR deadline',
        'Require even more time',
        ' Deadline extended by 30 days'
      ]

      expect(cases_show_page.case_history.rows.first.details.text).to eq(expected_case_history.join)
      expect(cases_show_page.case_status.deadlines.final.text).to eq(expected_final_date)
    end
  end
end
