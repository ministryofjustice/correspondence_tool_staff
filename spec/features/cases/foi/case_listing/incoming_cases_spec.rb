require 'rails_helper'

feature 'listing incoming on the system' do
  given(:disclosure_specialist) { create :disclosure_specialist }
  given(:press_officer) { create :press_officer }
  given(:private_officer) { create :private_officer }

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
           disclosure_assignment_state: 'pending',
           created_at: 2.business_days.ago,
           identifier: 'assigned_case_flagged_for_press_office_accepted'
  end
  given(:assigned_cr_case_flagged_for_press_office_accepted) do
    create :awaiting_responder_compliance_review,
           :flagged_accepted,
           :press_office,
           created_at: 2.business_days.ago,
           identifier: 'assigned_cr_case_flagged_for_press_office_accepted'
  end

  given(:assigned_case_flagged_for_private_office_accepted) do
    create :assigned_case,
           :flagged_accepted,
           :private_office,
           created_at: 2.business_days.ago,
           identifier: 'assigned_case_flagged_for_private_office_accepted'
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

      expect(cases.count).to eq 2
      expect(cases.first.number)
        .to have_text assigned_case_flagged_for_dacu_disclosure.number
      expect(cases.second.number)
        .to have_text assigned_case_flagged_for_press_office_accepted.number
    end
  end

  context 'with cases setup for press office' do
    given(:too_old_assigned_case) { create :assigned_case,
                                           created_at: 4.business_days.ago,
                                           identifier: 'too_old_assigned_case' }

    background do
      too_old_assigned_case
      assigned_case_flagged_for_dacu_disclosure
      assigned_case_flagged_for_press_office_accepted
      assigned_cr_case_flagged_for_press_office_accepted
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

  context 'with cases setup for private office' do
    given(:too_old_assigned_case) { create :assigned_case,
                                           created_at: 4.business_days.ago,
                                           identifier: 'too_old_assigned_case' }

    background do
      too_old_assigned_case
      assigned_case_flagged_for_dacu_disclosure
      assigned_case_flagged_for_private_office_accepted
      assigned_case
      fresh_assigned_case
    end

    scenario 'for press office' do
      login_as private_officer

      visit '/cases/incoming'

      cases = incoming_cases_page.case_list

      expect(cases.count).to eq 2
      expect(cases.first.number).to have_text assigned_case.number
      expect(cases.second.number)
          .to have_text assigned_case_flagged_for_dacu_disclosure.number
    end
  end
end
