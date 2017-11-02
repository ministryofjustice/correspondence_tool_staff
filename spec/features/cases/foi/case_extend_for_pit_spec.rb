require "rails_helper"

feature 'Applying a PIT extension to a case' do
  given(:manager)            { create :disclosure_bmt_user }
  given(:case_being_drafted) { create :case_being_drafted }

  background do
    login_as manager
  end

  scenario 'manager applies the extension' do
    cases_show_page.load(id: case_being_drafted.id)
    expect(cases_show_page).to have_extend_for_pit_action
  end
end
