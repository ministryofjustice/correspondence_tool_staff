require "rails_helper"

feature "Linking a case" do
  background do
    team = find_or_create :team_dacu
    bmt_user = team.users.first
    login_as bmt_user
  end

  scenario "editing a case in drafting state" do
    kase_1 = create :accepted_case
    link_a_case_step(kase: kase_1)
  end

  scenario "editing a case in unassigned state" do
    kase_1 = create :case
    link_a_case_step(kase: kase_1)
  end
end
