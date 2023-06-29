require "rails_helper"

feature "creating ICO Overturned FOI case" do
  given(:manager) { find_or_create :disclosure_bmt_user }

  background do
    login_as manager
    cases_page.load
  end

  scenario "ICO Appeal already has an overturned case created for it", js: true do
    existing_overturned_case = create(:overturned_ico_foi)
    ico_case = existing_overturned_case.original_ico_appeal
    cases_show_page.load(id: ico_case.id)

    expect(cases_show_page.actions).not_to have_create_overturned
  end
end
