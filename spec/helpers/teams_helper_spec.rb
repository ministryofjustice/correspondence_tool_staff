require 'rails_helper'

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
  describe '#sub_heading_for_teams' do
    it 'returns the appropriate message when creating a new team' do
      expect(sub_heading_for_teams(true))
          .to eq 'New team'
    end

    it 'returns the appropriate message when only editing an existing team' do
      expect(sub_heading_for_teams(false))
          .to eq 'Editing team'
    end
  end

  describe '#show_deactivate_link_or_info' do
    let(:manager)                   { create :manager}
    let(:empty_dir)                 { create :directorate }
    let(:dir_with_active_children)  { create :directorate }
    let!(:bu)                       { create :business_unit,
                                              directorate: dir_with_active_children }
    let(:user)                      { create :responder }
    let(:bu_with_users)             { user.teams.first }

    context "deactivatig directorate" do
      it 'returns a link for a team with no active children' do
        expect(show_deactivate_link_or_info(manager, empty_dir)).to eq(
          link_to "Deactivate Directorate", team_path(empty_dir.id),
                                data: {:confirm => I18n.t('.teams.directorate_detail.destroy')},
                                method: :delete,
                                id: 'deactivate-team-link'
        )
      end

      it 'returns a message if the team has active children' do
        expect(show_deactivate_link_or_info(manager, dir_with_active_children)).to eq(
          "To deactivate this directorate you need to first deactivate all business units within it."
        )
      end
    end
    context "deactivatig business unit" do
      it 'returns a link for a team with no active children' do
        expect(show_deactivate_link_or_info(manager, bu)).to eq(
          link_to "Deactivate Businesss unit", team_path(bu.id),
                                data: {:confirm => I18n.t('.teams.business_unit_detail.destroy')},
                                method: :delete,
                                id: 'deactivate-team-link'
        )
      end

      it 'returns a message if the team has active children' do
        expect(show_deactivate_link_or_info(manager, bu_with_users)).to eq(
          "To deactivate this business_unit you need to first deactivate all business units within it."
        )
      end
    end
  end
end
