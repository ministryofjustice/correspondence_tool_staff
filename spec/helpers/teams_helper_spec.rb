require "rails_helper"

# Specs in this file have access to a helper object that includes
# the TeamsHelperHelper. For example:
#
# describe TeamsHelperHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe TeamsHelper, type: :helper do
  describe "#sub_heading_for_teams" do
    it "returns the appropriate message when creating a new team" do
      expect(sub_heading_for_teams(true))
          .to eq "New team"
    end

    it "returns the appropriate message when only editing an existing team" do
      expect(sub_heading_for_teams(false))
          .to eq "Editing team"
    end
  end

  describe "#show_join_link_or_info" do
    let(:foi_responding_team) { find_or_create(:foi_responding_team) }
    let(:disclosure_team) { find_or_create(:team_disclosure) }

    it "returns a link if the team has no code" do
      expect(show_join_link_or_info(foi_responding_team)).to eq(
        link_to("Join business unit", join_teams_team_path(foi_responding_team.id), id: "join-team-link"),
      )
    end

    it "returns a message if the team has a code" do
      expect(show_join_link_or_info(disclosure_team)).to eq(
        t("teams.join.cannot_join_other_team", team_name: disclosure_team.name),
      )
    end
  end

  describe "#show_deactivate_link_or_info" do
    let(:manager)                   { create :manager }
    let(:empty_dir)                 { create :directorate }
    let(:dir_with_active_children)  { create :directorate }
    let!(:bu)                       do
      create :business_unit,
             directorate: dir_with_active_children
    end
    let(:user)                      { create :responder }
    let(:bu_with_users)             { user.teams.first }

    context "deactivating directorate" do
      it "returns a link for a team with no active children" do
        expect(show_deactivate_link_or_info(manager, empty_dir)).to eq(
          link_to("Deactivate directorate", team_path(empty_dir.id),
                  data: { confirm: I18n.t(".teams.directorate_detail.destroy") },
                  method: :delete,
                  id: "deactivate-team-link"),
        )
      end

      it "returns a message if the team has active children" do
        expect(show_deactivate_link_or_info(manager, dir_with_active_children)).to eq(
          "To deactivate this directorate you need to first deactivate all business units within it.",
        )
      end
    end

    context "deactivating business unit" do
      it "returns a link for a team with no active children" do
        expect(show_deactivate_link_or_info(manager, bu)).to eq(
          link_to("Deactivate business unit", team_path(bu.id),
                  data: { confirm: I18n.t(".teams.business_unit_detail.destroy") },
                  method: :delete,
                  id: "deactivate-team-link"),
        )
      end

      it "returns a message if the team has active children" do
        expect(show_deactivate_link_or_info(manager, bu_with_users)).to eq(
          "To deactivate this business unit you need to first deactivate all users within it.",
        )
      end
    end
  end

  describe "join_teams_back_link" do
    let(:business_unit) { create :business_unit }

    context "given a team" do
      it "returns a link to the join teams page" do
        expect(join_teams_back_link(business_unit)).to eq(
          link_to("Back", join_teams_back_url(business_unit), class: "govuk-back-link"),
        )
      end
    end
  end

  describe "join_teams_cancel_link" do
    let(:business_unit) { create :business_unit }

    context "given a team" do
      it "returns a link to the join teams page" do
        expect(join_teams_cancel_link(business_unit)).to eq(
          link_to("Cancel", join_teams_back_url(business_unit)),
        )
      end
    end
  end

  describe "move_to_directorate_back_link" do
    let(:business_unit) { create :business_unit }

    context "given a team" do
      it "returns a link to the move to directorate teams page" do
        expect(move_to_directorate_back_link(business_unit)).to eq(
          link_to("Back", move_to_directorate_back_url(business_unit), class: "govuk-back-link"),
        )
      end
    end
  end

  describe "move_to_directorate_cancel_link" do
    let(:business_unit) { create :business_unit }

    context "given a team" do
      it "returns a link to the move to directorate teams page" do
        expect(move_to_directorate_cancel_link(business_unit)).to eq(
          link_to("Cancel", move_to_directorate_back_url(business_unit)),
        )
      end
    end
  end

  describe "move_to_business_group_back_link" do
    let(:directorate) { create :directorate }

    context "given a directorate" do
      it "returns a link to the move to business groups page" do
        expect(move_to_business_group_back_link(directorate)).to eq(
          link_to("Back", move_to_business_group_back_url(directorate), class: "govuk-back-link"),
        )
      end
    end
  end

  describe "move_to_business_group_cancel_link" do
    let(:directorate) { create :directorate }

    context "given a team" do
      it "returns a link to the move to directorate teams page" do
        expect(move_to_business_group_cancel_link(directorate)).to eq(
          link_to("Cancel", move_to_business_group_back_url(directorate)),
        )
      end
    end
  end
end
