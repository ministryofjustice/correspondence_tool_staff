require "rails_helper"

feature "deleting FOI cases" do
  background do
    team = find_or_create :team_dacu
    bmt_user = team.users.first
    login_as bmt_user
  end

  scenario "deleting an open FOI case without any linked cases." do
    foi_case = create :accepted_case
    cases_show_page.load(id: foi_case.id)
    delete_case_step(kase: foi_case)
  end

  scenario "deleting an open FOI case without any linked cases." do
    kase_1 = create :accepted_case
    link_a_case_step(kase: kase_1)
    delete_case_step(kase: kase_1, has_linked_case: true)
  end
end
