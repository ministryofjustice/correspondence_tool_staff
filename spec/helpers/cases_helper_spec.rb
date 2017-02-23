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

  describe '#action_button_for(event)' do

    context 'when event == :assign_responder' do
      it 'generates HTML that links to the new assignment page' do
        @case = create(:case)
        expect(action_button_for(:assign_responder)).to eq(
          "<a class=\"button\" href=\"/cases/#{@case.id}/assignments/new\">Assign to a responder</a>")
      end
    end

    context 'when event == :accept_responder_assignment' do
      it 'generates HTML that links to the accept or reject assignment page' do
        @case = create(:assigned_case)
        @assignment = @case.assignments.last
        expect(action_button_for(:accept_responder_assignment)).to eq(
"<a class=\"button\" \
href=\"/cases/#{@case.id}/assignments/#{@assignment.id}/edit\"\
>Accept or reject</a>"
          )
      end
    end

    context 'when event == :reject_responder_assignment' do
      it 'generates HTML that links to the accept or reject assignment page' do
        @case = create(:assigned_case)
        @assignment = @case.assignments.last
        expect(action_button_for(:accept_responder_assignment)).to eq(
"<a class=\"button\" \
href=\"/cases/#{@case.id}/assignments/#{@assignment.id}/edit\"\
>Accept or reject</a>"
          )
      end
    end

    context 'when event == :close' do
      it 'generates HTML that links to the close case action' do
        @case = create(:responded_case)
        expect(action_button_for(:close)).to eq(
"<a class=\"button\" rel=\"nofollow\" data-method=\"patch\" \
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
"<a class=\"button\" \
href=\"/cases/#{@case.id}/respond\">Mark response as sent</a>"
          )
      end
    end
  end
end
