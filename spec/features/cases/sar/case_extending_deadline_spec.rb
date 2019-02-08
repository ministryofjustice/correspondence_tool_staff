require "rails_helper"

feature 'extending a SAR case deadline' do
  include Features::Interactions

  given(:manager)   { find_or_create :disclosure_bmt_user }
  given(:approver)  { create :disclosure_specialist }
  given(:responder) { kase.responder }
  given!(:kase)     { create :accepted_sar }

  context 'a manager' do
    scenario 'extending a SAR case by 30 days twice then removing extension deadline' do
      # Expected dates for display
      original_final_deadline = kase.external_deadline
      expected_initial_extension_date = (original_final_deadline + 30.days).strftime('%-d %b %Y')
      expected_final_extension_date = (original_final_deadline + 60.days).strftime('%-d %b %Y')

      login_as manager

      # 1. Can extend SAR deadline only
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.actions).to have_extend_sar_deadline
      expect(cases_show_page.actions).not_to have_remove_sar_deadline_extension

      # 2. Extend by 30 days for the first time
      extend_sar_deadline_for(kase, 30) do |page|
        page.extension_period_30_days.click
      end

      case_deadline_text_to_be(expected_initial_extension_date)

      # 3. Extending again does not give you any extension periods for selection
      extend_sar_deadline_for(kase, 30, reason: 'Need even more time') do |page|
        expect(page).not_to have_extension_period_30_days
        expect(page).to have_text('The deadline for this case will be extended by a further 30 days.')
      end

      case_deadline_text_to_be(expected_final_extension_date)

      # 4. No longer able to extend
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.actions).not_to have_extend_sar_deadline
      expect(cases_show_page.actions).to have_remove_sar_deadline_extension

      # 5. Remove extension should display initial deadline
      cases_show_page.actions.remove_sar_deadline_extension.click
      expect(cases_show_page).to be_displayed
      case_deadline_text_to_be(original_final_deadline.strftime('%-d %b %Y'))
    end
  end
end
