require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the CasesHelper. For example:
#
# describe CasesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe CasesHelper, type: :helper do

  let(:drafter)   { create(:user, roles: ['drafter'])   }
  let(:assigner)  { create(:user, roles: ['assigner'])  }

  describe '#action_button_for(event)' do

    context 'when event == :assign_responder' do
      it 'generates HTML that links to the new assignment page' do
        @case = create(:case)
        expect(action_button_for(:assign_responder)).to eq(
          "<a class=\"button\" href=\"/cases/#{@case.id}/assignments/new\">Assign to a responder</a>")
      end
    end

    context 'when event == :close' do
      it 'generates HTML that links to the close case action' do
        @case = create(:responded_case)
        expect(action_button_for(:close)).to eq(
"<a id=\"action--close-case\" class=\"button\" data-method=\"get\" \
href=\"/cases/#{@case.id}/close\">Close case</a>"
          )
      end
    end

    context 'when event == :add_responses' do
      it 'generates HTML that links to the upload response page' do
        @case = create(:accepted_case)
        expect(action_button_for(:add_responses)).to eq(
"<a class=\"button\" \
href=\"/cases/#{@case.id}/new_response_upload\">Upload response</a>"
          )
      end
    end

    context 'when event = ":respond' do
      it 'generates HTML that links to the upload response page' do
        @case = create(:case_with_response)
        expect(action_button_for(:respond)).to eq(
"<a id=\"action--mark-response-as-sent\" class=\"button\" \
href=\"/cases/#{@case.id}/respond\">Mark response as sent</a>"
          )
      end
    end
  end

  describe '#timeliness' do
    it 'returns correct string for answered in time' do
      expect(timeliness(create :closed_case)).to eq 'Answered in time'
    end

    it 'returns correct string for answered late' do
      expect(timeliness(create :closed_case, :late)).to eq 'Answered late'
    end
  end

  describe '#time_taken' do
    it 'returns the number of business days taken to respond to a case' do
      expect(time_taken(create :closed_case))
        .to eq '18 working days'
    end

    it 'uses singular "day" for 1 day' do
      expect(time_taken(create :closed_case,
                               date_responded: 21.business_days.ago))
        .to eq '1 working day'
    end
  end
end
