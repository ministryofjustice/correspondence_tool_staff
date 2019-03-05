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

  let(:manager)           { create :manager }
  let(:responder)         { create :responder }
  let(:coworker)          { create :responder,
                                    responding_teams: responder.responding_teams }
  let(:another_responder) { create :responder }
  let(:approver)          { create :approver }

  describe '#manager_updating_close_details_on_old_case?' do

    let(:old_style_closed_case)   { create :closed_case, :old_without_info_held }
    let(:new_style_closed_case)   { create :closed_case }
    let(:open_case)               { create :assigned_case }

    context 'manager' do
      context 'case_closed' do
        context 'old_style closure details on case' do
          it 'returns true' do
            expect(manager_updating_close_details_on_old_case?(manager, old_style_closed_case)).to be true
          end
        end

        context 'new style closure details' do
          it 'returns false' do
            expect(manager_updating_close_details_on_old_case?(manager, new_style_closed_case)).to be false
          end
        end
      end

      context 'case open' do
        it 'returns false' do
          expect(manager_updating_close_details_on_old_case?(manager, open_case)).to be false
        end
      end
    end

    context 'approver' do
      context 'case closed' do
        context 'old style closure details' do
          it 'returns false' do
            expect(manager_updating_close_details_on_old_case?(approver, old_style_closed_case)).to be false
          end
        end
        context 'new style closure details' do
          it 'returns false' do
            expect(manager_updating_close_details_on_old_case?(approver, new_style_closed_case)).to be false
          end
        end
      end
    end

    context 'responder' do
      context 'case closed' do
        context 'old style closure details' do
          it 'returns false' do
            expect(manager_updating_close_details_on_old_case?(responder, old_style_closed_case)).to be false
          end
        end
        context 'new style closure details' do
          it 'returns false' do
            expect(manager_updating_close_details_on_old_case?(responder, new_style_closed_case)).to be false
          end
        end
      end
    end
  end


  describe '#action_button_for(event)' do

    context 'when event == :assign_responder' do
      it 'generates HTML that links to the new assignment page' do
        @case = create(:case)
        expect(action_button_for(:assign_responder)).to eq(
          "<a id=\"action--assign-to-responder\" class=\"button\" href=\"/cases/#{@case.id}/assignments/new\">Assign to a responder</a>")
      end
    end

    context 'when event == :close' do
      context 'case is foi' do
        it 'generates HTML that links to the close case action' do
          @case = create(:responded_case)
          expect(action_button_for(:close)).to eq(
  "<a id=\"action--close-case\" class=\"button\" data-method=\"get\" \
href=\"/cases/#{@case.id}/close\">Close case</a>"
            )
        end
      end


      context 'case is ICO' do
        it 'generates HTML that links to the close case action' do
          @case = create(:responded_ico_foi_case)
          expect(action_button_for(:close)).to eq(
  "<a id=\"action--close-case\" class=\"button\" data-method=\"get\" \
href=\"/cases/#{@case.id}/close\">Record ICO&#39;s decision</a>"
            )
        end
      end
    end

    context 'when event == :progress_for_clearance' do
      it 'generates HTML that links to the progress_for_clearance case action' do
        @case = create(:accepted_sar, :flagged)
        expect(action_button_for(:progress_for_clearance)).to eq(
"<a id=\"action--progress-for-clearance\" class=\"button\" rel=\"nofollow\" data-method=\"patch\" href=\"/cases/#{@case.id}/progress_for_clearance\">Ready for Disclosure clearance</a>"          )
      end
    end

    context 'when event == :add_responses' do
      context 'case does not require clearance' do
        it 'generates HTML that links to the upload response page' do
          @case = create(:accepted_case)
          expect(action_button_for(:add_responses)).to eq(
             "<a id=\"action--upload-response\" class=\"button\" href=\"/cases/#{@case.id}/upload_responses\">Upload response</a>"
            )
        end
      end

      context 'case requires clearance' do
        it 'generates HTML that links to the upload response page' do
          @case = create(:accepted_case)
          expect(action_button_for(:add_responses)).to eq(
           "<a id=\"action--upload-response\" class=\"button\" href=\"/cases/#{@case.id}/upload_responses\">Upload response</a>"
         )
        end
      end
    end

    context 'when event = :respond' do
      context 'case is FOI/SAR' do
        it 'generates HTML that links to the upload response page' do
          @case = create(:case_with_response)
          expect(action_button_for(:respond)).to eq(
  "<a id=\"action--mark-response-as-sent\" class=\"button\" \
href=\"/cases/#{@case.id}/respond\">Mark response as sent</a>"
            )
        end
      end

      context 'case is ICO' do
        it 'generates HTML that links to the upload response page' do
          @case = create(:approved_ico_foi_case)
          expect(action_button_for(:respond)).to eq(
  "<a id=\"action--mark-response-as-sent\" class=\"button\" \
href=\"/cases/#{@case.id}/respond\">Mark as sent to ICO</a>"
            )
        end
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
                   %[<a id="action--reassign-case" class="button" \
href="/cases/#{@case.id}/assignments/#{@assignments.first.id}/reassign_user">Change team member</a>]
                 )
        end
      end


      context 'when there are two assignemnts for this users teams' do
        it 'generates a link to the select_team page' do
          @case = create(:accepted_case, :flagged)
          @assignments = [ @case.responder_assignment, @case.approver_assignments.first ]
          expect(action_button_for(:reassign_user)).to eq(
                 %[<a id="action--reassign-case" class="button" \
href="/cases/#{@case.id}/assignments/select_team?assignment_ids=#{@assignments.first.id}%2B#{@assignments.last.id}">Change team member</a>]
               )
        end
      end
    end

    context 'when event == :upload_response_and_approve' do
      it 'generates HTML that links to the ' do
        @case = create(:pending_dacu_clearance_case)
        expect(action_button_for(:upload_response_and_approve))
          .to eq(
                "<a id=\"action--upload-approve\" class=\"button\" href=\"/cases/#{@case.id}/upload_response_and_approve\">Upload response and clear</a>"
              )
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

    context 'query hash instance variable exists' do
      context 'page parameters exists' do
        it 'shows link with hash and position parameters' do
          expected_link = "<a href=\"/cases/25?pos=35\">180425001</a>"
          expect(case_link_with_hash(kase, :number, 2, 14)).to eq expected_link
        end
      end

      context 'page number does not exist' do
        it 'shows link with hash and position parameters based on page 1' do
          expected_link = "<a href=\"/cases/25?pos=15\">180425001</a>"
          expect(case_link_with_hash(kase, :number, '', 14)).to eq expected_link
        end
      end
    end
  end

  describe '#case_details_links' do
    it 'adds a link to edit case details if permitted' do
      kase = create(:case_being_drafted)
      user = find_or_create(:disclosure_bmt_user)
      result = case_details_links(kase, user)
      expect(result).to eq link_to('Edit case details',
                                        "/cases/#{kase.id}/edit",
                                        class: "secondary-action-link")
    end

    it 'adds a link to edit closure details if permitted' do
      kase = create(:closed_sar)
      user = find_or_create(:disclosure_bmt_user)
      result = case_details_links(kase, user)
      edit_case_link = link_to('Edit case details',
                               "/cases/#{kase.id}/edit",
                               class: "secondary-action-link")
      edit_closure_link = link_to('Edit closure details',
                                  "/cases/#{kase.id}/edit_closure",
                                  class: "secondary-action-link")
      expect(result).to eq "#{edit_case_link}#{edit_closure_link}"
    end
  end

  describe '#case_details_for_link_type' do
    it 'returns case-details for empty link type' do
      expect(case_details_for_link_type(nil)).to eq 'case-details'
    end

    it 'returns original-case-details for original link types' do
      expect(case_details_for_link_type('original')).to eq 'original-case-details'
    end
  end

  describe '#download_csv_link' do

    let(:base_path)     { '/cases/open' }
    let(:param_path)    { '/cases/open?page=3&type=foi' }

    context 'no query params' do
      it 'returns link for csv without query params' do
        expect(download_csv_link(base_path)).to eq %q{<a href="/cases/open.csv">Download cases</a>}
      end
    end

    context 'with query params' do
      it 'returns link for csv with query params' do
        expect(download_csv_link(param_path)).to eq %q{<a href="/cases/open.csv?page=3&amp;type=foi">Download cases</a>}
      end
    end

  end
end
