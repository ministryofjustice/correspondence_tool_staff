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
  describe '#assign_button_text' do
    it 'returns the appropriate text when assigning a new case' do
      expect(assign_button_text(true))
        .to eq 'Create and assign case'
    end

    it 'returns the appropriate text when only assigning a case' do
      expect(assign_button_text(false))
        .to eq 'Assign case'
    end
  end

  describe '#page_heading' do
    it 'returns the appropriate message when assigning a new case' do
      expect(page_heading(true))
        .to eq 'Create and assign case'
    end

    it 'returns the appropriate message when only assigning a case' do
      expect(page_heading(false))
        .to eq 'Assign case'
    end
  end
end
