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

  let(:manager)   { create :manager }
  let(:responder) { create :responder }
  let(:coworker)  { create :responder,
                           responding_teams: responder.responding_teams }
  let(:another_responder) { create :responder }

  describe '#action_button_for(event)' do

    context 'when event == :assign_responder' do
      it 'generates HTML that links to the new assignment page' do
        @case = create(:case)
        expect(action_button_for(:assign_responder)).to eq(
          "<a id=\"action--assign-to-responder\" class=\"button\" href=\"/cases/#{@case.id}/assignments/new\">Assign to a responder</a>")
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
      context 'case does not require clearance' do
        it 'generates HTML that links to the upload response page' do
          @case = create(:accepted_case)
          expect(@case).to receive(:requires_clearance?).and_return(false)
          expect(action_button_for(:add_responses)).to eq(
             "<a id=\"action--upload-response\" class=\"button\" href=\"/cases/#{@case.id}/new_response_upload?mode=upload\">Upload response</a>"
            )
        end
      end

      context 'case requires clearance' do
        it 'generates HTML that links to the upload response page' do
          @case = create(:accepted_case)
          expect(@case).to receive(:requires_clearance?).and_return(true)
          expect(action_button_for(:add_responses)).to eq(
           "<a id=\"action--upload-response\" class=\"button\" href=\"/cases/#{@case.id}/new_response_upload?mode=upload-flagged\">Upload response</a>"
         )
        end
      end

    end

    context 'when event = :respond' do
      it 'generates HTML that links to the upload response page' do
        @case = create(:case_with_response)
        expect(action_button_for(:respond)).to eq(
"<a id=\"action--mark-response-as-sent\" class=\"button\" \
href=\"/cases/#{@case.id}/respond\">Mark response as sent</a>"
          )
      end
    end

    context 'when event = :request_amends' do
      it 'generates an HTML link to cases/request_amends' do
        @case = create(:case)
        expect(action_button_for(:request_amends))
          .to eq "<a id=\"action--request-amends\" " +
                 "class=\"button\" " +
                 "href=\"/cases/#{@case.id}/request_amends\">" +
                 "Request amends</a>"
      end
    end

    context 'when event == :reassign_user' do
      context 'when there is only one assignment for this users teams' do
        it 'generates HTML that links to the close case action' do
          @case = create(:accepted_case)
          @assignments = [@case.responder_assignment]
          expect(action_button_for(:reassign_user)).to eq(
                   %[<a id="action--reassign-case" class="button" href="/cases/#{@case.id}/assignments/#{@assignments.first.id}/reassign_user">Change team member</a>]
                 )
        end
      end


      context 'when there are two assignemnts for this users teams' do
        it 'generates a link to the select_team page' do
          @case = create(:accepted_case, :flagged)
          @assignments = [ @case.responder_assignment, @case.approver_assignments.first ]
          expect(action_button_for(:reassign_user)).to eq(
                 %[<a id="action--reassign-case" class="button" href="/cases/#{@case.id}/assignments/select_team?assignment_ids=#{@assignments.first.id}%2B#{@assignments.last.id}">Change team member</a>]
               )
        end
      end
    end
  end

  describe '#case_uploaded_request_files_class' do
    before do
      @case = create(:case)
    end

    it 'returns nil when case has no errors on uploaded_request_files' do
      expect(case_uploaded_request_files_class).to be_nil
    end

    it 'returns error class when case has errors on uploaded_request_files' do
      @case.errors.add(:uploaded_request_files, :blank)
      expect(case_uploaded_request_files_class).to eq 'error'
    end
  end

  describe '#case_uploaded_request_files_id' do
    before do
      @case = create(:case)
    end

    it 'returns nil when case has no errors on uploaded_request_files' do
      expect(case_uploaded_request_files_id).to be_nil
    end

    it 'returns error id when case has errors on uploaded_request_files' do
      @case.errors.add(:uploaded_request_files, :blank)
      expect(case_uploaded_request_files_id)
        .to eq 'error_case_uploaded_request_files'
    end
  end

  describe '#action_links_for_allowed_events' do
    let(:policy_double) { double 'Pundit::Policy',
                                 one?: true,
                                 two?: false,
                                 three?: true }

    it 'generates links for allowed events' do
      @case = :case
      allow_any_instance_of(CasesHelper).to receive(:policy).with(:case).and_return(policy_double)
      allow_any_instance_of(CasesHelper).to receive(:action_link_for_one).with(:case).and_return('link_one')
      allow_any_instance_of(CasesHelper).to receive(:action_link_for_three).with(:case).and_return('link_three')
      links = action_links_for_allowed_events(@case, :one, :two, :three)
      expect(links).to eq ['link_one', 'link_three']
    end
  end

  describe '#request_details_html' do
    it 'generates html markup' do
      kase = instance_double(Case::Base, subject: 'Once upon a time...', name: 'Ray Gunn')
      request_details = request_details_html(kase)
      expect(request_details).to eq '<strong class="strong">Once upon a time... </strong><div class="case-name-detail">Ray Gunn</div>'
    end
  end
  
  describe '#case_link_with_hash' do
    let(:kase) {double 'case', id: 25, number: '180425001'}

    context 'no query hash instance variable' do
      it 'shows link without hash and position parameters' do
        expected_link = "<a href=\"/cases/25\">180425001</a>"
        expect(case_link_with_hash(kase, :number, nil, 3, 44)).to eq expected_link
      end
    end

    context 'query hash instance variable exists' do
      context 'page parameters exists' do
        it 'shows link with hash and position parameters' do
          expected_link = "<a href=\"/cases/25?hash=XYZ&amp;pos=35\">180425001</a>"
          expect(case_link_with_hash(kase, :number, 'XYZ', 2, 14)).to eq expected_link
        end
      end

      context 'page number does not exist' do
        it 'shows link with hash and position parameters based on page 1' do
          expected_link = "<a href=\"/cases/25?hash=XYZ&amp;pos=15\">180425001</a>"
          expect(case_link_with_hash(kase, :number, 'XYZ', '', 14)).to eq expected_link
        end
      end
    end
  end
end
