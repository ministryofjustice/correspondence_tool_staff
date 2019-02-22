require "rails_helper"

feature 'when extending a SAR case deadline' do
  include Features::Interactions

  given(:manager)             { find_or_create :disclosure_bmt_user }
  given!(:original_deadline)  { kase.external_deadline }

  context 'a manager' do
    given!(:kase)     { create :accepted_sar }

    scenario 'extending a SAR case by 30 days twice then removing extension deadline' do
      # Expected dates for display
      expected_initial_extension_date = (original_deadline + 30.days).strftime('%-d %b %Y')
      expected_final_extension_date = (original_deadline + 60.days).strftime('%-d %b %Y')

      login_as manager

      # 1. Can extend SAR deadline only
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.actions).to have_extend_sar_deadline
      expect(cases_show_page.actions).not_to have_remove_sar_deadline_extension

      # 2. Extend by 30 days for the first time
      extend_sar_deadline_for(kase: kase, num_days: 30) do |page|
        page.extension_period_30_days.click
      end

      case_deadline_text_to_be(expected_initial_extension_date)

      # 3. Extending again does not give you any extension periods for selection
      extend_sar_deadline_for(kase: kase, num_days: 30, reason: 'Need even more time') do |page|
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
      case_deadline_text_to_be(original_deadline.strftime('%-d %b %Y'))
    end

    scenario 'extending a SAR case by 60 days' do
      # Expected dates for display
      original_deadline = kase.external_deadline
      expected_final_extension_date = (original_deadline + 60.days).strftime('%-d %b %Y')

      login_as manager

      # 1. Extend by 60 days
      extend_sar_deadline_for(kase: kase, num_days: 60) do |page|
        page.extension_period_60_days.click
      end

      case_deadline_text_to_be(expected_final_extension_date)

      # 2. No longer able to extend
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.actions).not_to have_extend_sar_deadline
      expect(cases_show_page.actions).to have_remove_sar_deadline_extension

      # 3. Trying to extend again displays an error message
      visit extend_sar_deadline_case_path(id: kase.id)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.alert.text).to eq('SAR deadline cannot be extended')
    end
  end

  context 'an approver' do
    given!(:approver) { find_or_create :disclosure_specialist }
    given!(:kase) {
      create :accepted_sar,
      :flagged_accepted,
      approver: approver
    }

    scenario 'can extend a SAR deadline' do
      login_as approver
      cases_show_page.load(id: kase.id)

      # 1. Extend by 30 days for the first time
      extend_sar_deadline_for(kase: kase, num_days: 30) do |page|
        page.extension_period_30_days.click
      end

      case_deadline_text_to_be((original_deadline + 30.days).strftime('%-d %b %Y'))
    end
  end

  context 'a responder' do
    given(:responder) { kase.responder }
    given!(:kase)     { create :accepted_sar }

    scenario 'cannot extend a SAR deadline' do
      login_as responder

      # 1. No button to extend deadline
      cases_show_page.load(id: kase.id)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.actions).not_to have_extend_sar_deadline

      # 2. Unauthorized to extend deadline
      visit extend_sar_deadline_case_path(id: kase.id)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.alert.text).to eq('SAR deadline cannot be extended')
    end
  end
end
