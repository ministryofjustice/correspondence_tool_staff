require "rails_helper"

describe "users/confirm_destroy.html.slim", type: :view do
  let(:responder)     { find_or_create :foi_responder }
  let(:team)          { find_or_create :foi_responding_team }
  let!(:kase)         { create :accepted_case }

  context "when user has one team" do
    it "shows" do
      assign(:user, responder)
      assign(:team, team)
      render

      users_destroy_page.load(rendered)
      expect(users_destroy_page.page_heading.heading)
        .to have_text "#{responder.full_name} has open cases"
      expect(users_destroy_page.page_heading.sub_heading)
        .to have_text "Deactivate team member "
      expect(users_destroy_page.deactivate_info)
        .to have_text "#{responder.full_name} has 1 open cases assigned to them. If you deactivate them, their cases will still be assigned to #{team.name} but a new team member will need to be assigned."
      expect(users_destroy_page)
        .not_to have_other_team_info
      expect(users_destroy_page)
        .to have_deactivate_user_button
    end
  end

  context "when user has one team" do
    let(:multiple_team_responder) do
      find_or_create :responder,
                     responding_teams: [team1, team2]
    end
    let!(:team1)                    { find_or_create :responding_team }
    let!(:team2)                    { create :responding_team }
    let!(:kase)                     do
      create :accepted_case,
             responder: multiple_team_responder
    end

    it "shows" do
      assign(:user, multiple_team_responder)
      assign(:team, team1)
      render

      users_destroy_page.load(rendered)
      expect(users_destroy_page.page_heading.heading)
        .to have_text "#{multiple_team_responder.full_name} has open cases"
      expect(users_destroy_page.page_heading.sub_heading)
        .to have_text "Deactivate team member "
      expect(users_destroy_page.deactivate_info)
        .to have_text "#{multiple_team_responder.full_name} has 1 open cases assigned to them. If you deactivate them, their cases will still be assigned to #{team1.name} but a new team member will need to be assigned."
      expect(users_destroy_page.other_team_info)
        .to have_text(
          "They are also a member of #{team2.name}",
        )
      expect(users_destroy_page)
        .to have_deactivate_user_button
    end
  end
end
