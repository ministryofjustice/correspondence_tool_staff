require "rails_helper"

feature 'viewing SAR cases' do
  given(:approver)          { create :approver }
  given(:manager)           { create :disclosure_bmt_user }
  given(:responder)         { create :responder }
  given(:another_responder) { create :responder }

  context 'unassigned case' do
    given!(:kase)   { create :sar_case }

    scenario 'viewing as a manager' do
      login_as manager

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
    end

    scenario 'viewing as a responder' do
      login_as responder

      cases_show_page.load id: kase.id
      expect(open_cases_page).to be_displayed(timeliness: 'in_time')
    end
  end

  context 'assigned case' do
    given!(:kase) { create :accepted_sar, responder: responder }

    scenario 'viewing as a manager' do
      login_as manager

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
    end

    scenario 'viewing as assigned responder' do
      login_as responder

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
    end

    scenario 'viewing as another responder' do
      login_as another_responder

      cases_show_page.load id: kase.id

      expect(open_cases_page).to be_displayed(timeliness: 'in_time')
    end
  end
end
