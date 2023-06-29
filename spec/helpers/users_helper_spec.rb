require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
  describe "#unassign_or_deactivate_link" do
    context "when user with live cases" do
      let(:responder)    { find_or_create :foi_responder }
      let(:team)         { find_or_create :foi_responding_team }
      let(:kase)         { create :accepted_case }

      it "generates a link to confirm_destroy page" do
        expect(unassign_or_deactivate_link(responder, team)).to eq(
          "<a class=\"button-secondary button-left-spacing\" id=\"deactivate-user-button\" rel=\"nofollow\" data-method=\"delete\" href=\"/teams/#{team.id}/users/#{responder.id}\">Deactivate team member</a>",
        )
      end
    end

    context "when user with no live cases" do
      let(:responder)    { find_or_create :foi_responder }
      let(:team)         { find_or_create :foi_responding_team }

      it "generates a link to delete the user" do
        expect(unassign_or_deactivate_link(responder, team)).to eq(
          link_to("Deactivate team member", team_user_path(team.id, responder.id),
                  method: :delete,
                  class: "button-secondary button-left-spacing",
                  id: "deactivate-user-button"),
        )
      end
    end
  end
end
