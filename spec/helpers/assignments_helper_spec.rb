require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the AssignmentsHelper. For example:
#
# describe AssignmentsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe AssignmentsHelper, type: :helper do

  describe '#page_heading' do
    it 'returns the appropriate message when assigning a new case' do
      expect(sub_heading(true))
        .to eq 'Create case'
    end

    it 'returns the appropriate message when only assigning a case' do
      expect(sub_heading(false))
        .to eq 'Existing case'
    end
  end
end
