require 'rails_helper'

feature 'listing incoming on the system' do
  given(:disclosure_specialist) { create :disclosure_specialist }
  given(:press_officer) { create :press_officer }

  given(:assigned_case) { create :assigned_case,
                                 created_at: 1.business_days.ago,
                                 identifier: 'assigned_case' }
  given(:fresh_assigned_case) { create :assigned_case,
                                       identifier: 'fresh_assigned_case' }
  given(:assigned_case_flagged_for_dacu_disclosure) do
    create :assigned_case,
           :flagged,
           :dacu_disclosure,
           created_at: 2.business_days.ago,
           identifier: 'assigned_case_flagged_for_dacu_disclosure'
  end
  given(:assigned_case_flagged_for_dacu_disclosure_accepted) do
    create :assigned_case,
           :flagged_accepted,
           :dacu_disclosure,
           created_at: 2.business_days.ago,
           identifier: 'assigned_case_flagged_for_dacu_disclosure_accepted'
  end
  given(:assigned_case_flagged_for_press_office_accepted) do
    create :assigned_case,
           :flagged_accepted,
           :press_office,
           created_at: 2.business_days.ago,
           identifier: 'assigned_case_flagged_for_press_office_accepted'
  end

  context 'with cases setup for dacu disclosure' do
    background do
      assigned_case
      assigned_case_flagged_for_dacu_disclosure
      assigned_case_flagged_for_dacu_disclosure_accepted
      assigned_case_flagged_for_press_office_accepted
    end

    scenario 'for dacu disclosure' do
      login_as disclosure_specialist

      visit '/cases/incoming'

      cases = incoming_cases_page.case_list

      expect(cases.count).to eq 1
      expect(cases.first.number)
        .to have_text assigned_case_flagged_for_dacu_disclosure.number
    end
  end

  context 'with cases setup for dacu disclosure' do
    given(:too_old_assigned_case) { create :assigned_case,
                                           created_at: 4.business_days.ago,
                                           identifier: 'too_old_assigned_case' }

    background do
      too_old_assigned_case
      assigned_case_flagged_for_dacu_disclosure
      assigned_case_flagged_for_press_office_accepted
      assigned_case
      fresh_assigned_case
    end

    scenario 'for press office' do
      login_as press_officer

      visit '/cases/incoming'

      cases = incoming_cases_page.case_list

      expect(cases.count).to eq 2
      expect(cases.first.number).to have_text assigned_case.number
      expect(cases.second.number)
        .to have_text assigned_case_flagged_for_dacu_disclosure.number
    end
  end
end
