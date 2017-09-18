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
end
