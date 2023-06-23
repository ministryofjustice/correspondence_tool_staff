require "rails_helper"

class MockCase
  def initialize(has_attribute:, within_escalation_deadline:, is_offender_sar:, is_offender_sar_complaint:)
    @has_attribute = has_attribute
    @within_escalation_deadline = within_escalation_deadline
    @is_offender_sar = is_offender_sar
    @is_offender_sar_complaint = is_offender_sar_complaint
  end

  def has_attribute?(_attr_name)
    @has_attribute
  end

  def within_escalation_deadline?
    @within_escalation_deadline
  end

  def type_of_offender_sar?
    @is_offender_sar || @is_offender_sar_complaint
  end

  def offender_sar_complaint?
    @is_offender_sar_complaint
  end
end

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
# rubocop:disable RSpec/InstanceVariable
RSpec.describe CasesHelper, type: :helper do
  let(:manager)           { create :manager }
  let(:responder)         { create :responder }
  let(:coworker)          do
    create :responder,
           responding_teams: responder.responding_teams
  end
  let(:another_responder) { create :responder }
  let(:approver)          { create :approver }

  describe "#manager_updating_close_details_on_old_case?" do
    let(:old_style_closed_case)   { create :closed_case, :old_without_info_held }
    let(:new_style_closed_case)   { create :closed_case }
    let(:open_case)               { create :assigned_case }

    context "when manager" do
      context "and case_closed" do
        context "and old_style closure details on case" do
          it "returns true" do
            expect(manager_updating_close_details_on_old_case?(manager, old_style_closed_case)).to be true
          end
        end

        context "and new style closure details" do
          it "returns false" do
            expect(manager_updating_close_details_on_old_case?(manager, new_style_closed_case)).to be false
          end
        end
      end

      context "and case open" do
        it "returns false" do
          expect(manager_updating_close_details_on_old_case?(manager, open_case)).to be false
        end
      end
    end

    context "when approver" do
      context "and case closed" do
        context "and old style closure details" do
          it "returns false" do
            expect(manager_updating_close_details_on_old_case?(approver, old_style_closed_case)).to be false
          end
        end

        context "and new style closure details" do
          it "returns false" do
            expect(manager_updating_close_details_on_old_case?(approver, new_style_closed_case)).to be false
          end
        end
      end
    end

    context "when responder" do
      context "and case closed" do
        context "and old style closure details" do
          it "returns false" do
            expect(manager_updating_close_details_on_old_case?(responder, old_style_closed_case)).to be false
          end
        end

        context "and new style closure details" do
          it "returns false" do
            expect(manager_updating_close_details_on_old_case?(responder, new_style_closed_case)).to be false
          end
        end
      end
    end
  end

  describe "#action_button_for(event)" do
    context "when event == :assign_responder" do
      it "generates HTML that links to the new assignment page" do
        @case = create(:case)
        expect(action_button_for(:assign_responder)).to eq(
          "<a id=\"action--assign-to-responder\" class=\"button\" href=\"/cases/#{@case.id}/assignments/new\">Assign to a responder</a>",
        )
      end
    end

    context "when event == :close" do
      context "and case is foi" do
        it "generates HTML that links to the close case action" do
          @case = create(:responded_case)
          expect(action_button_for(:close)).to eq(
            "<a id=\"action--close-case\" class=\"button\" data-method=\"get\" \
href=\"/cases/fois/#{@case.id}/close\">Close case</a>",
          )
        end
      end

      context "and case is ICO" do
        it "generates HTML that links to the close case action" do
          @case = create(:responded_ico_foi_case)
          expect(action_button_for(:close)).to eq(
            "<a id=\"action--close-case\" class=\"button\" data-method=\"get\" \
href=\"/cases/ico_fois/#{@case.id}/close\">Record ICO&#39;s decision</a>",
          )
        end
      end
    end

    context "when event == :progress_for_clearance" do
      it "generates HTML that links to the progress_for_clearance case action" do
        @case = create(:accepted_sar, :flagged)
        expect(action_button_for(:progress_for_clearance)).to eq(
          "<a id=\"action--progress-for-clearance\" class=\"button\" rel=\"nofollow\" data-method=\"patch\" href=\"/cases/#{@case.id}/clearances/progress_for_clearance\">Ready for Disclosure clearance</a>",
        )
      end
    end

    context "when event == :add_responses" do
      it "generates HTML that links to the upload response page" do
        @case = create(:accepted_case)
        expect(action_button_for(:add_responses)).to eq(
          "<a id=\"action--upload-response\" class=\"button\" href=\"/cases/#{@case.id}/responses/new/upload_responses\">Upload response</a>",
        )
      end
    end

    context "when event = :respond" do
      context "and case is FOI/SAR" do
        it "generates HTML that links to the upload response page" do
          @case = create(:case_with_response)
          expect(action_button_for(:respond)).to eq(
            "<a id=\"action--mark-response-as-sent\" class=\"button\" \
href=\"/cases/fois/#{@case.id}/respond\">Mark response as sent</a>",
          )
        end
      end

      context "and case is ICO" do
        it "generates HTML that links to the upload response page" do
          @case = create(:approved_ico_foi_case)
          expect(action_button_for(:respond)).to eq(
            "<a id=\"action--mark-response-as-sent\" class=\"button\" \
href=\"/cases/ico_fois/#{@case.id}/respond\">Mark as sent to ICO</a>",
          )
        end
      end
    end

    context "when event = :request_amends" do
      it "generates an HTML link to cases/request_amends" do
        @case = create(:case)
        expect(action_button_for(:request_amends))
          .to eq "<a id=\"action--request-amends\" " \
            "class=\"button\" " \
            "href=\"/cases/#{@case.id}/amendments/new\">" \
            "Request amends</a>"
      end
    end

    context "when event == :reassign_user" do
      context "and there is only one assignment for this users teams" do
        it "generates HTML that links to the close case action" do
          @case = create(:accepted_case)
          @assignments = [@case.responder_assignment]
          expect(action_button_for(:reassign_user)).to eq(
            %(<a id="action--reassign-case" class="button" \
href="/cases/#{@case.id}/assignments/#{@assignments.first.id}/reassign_user">Change team member</a>),
          )
        end
      end

      context "when there are two assignemnts for this users teams" do
        it "generates a link to the select_team page" do
          @case = create(:accepted_case, :flagged)
          @assignments = [@case.responder_assignment, @case.approver_assignments.first]
          expect(action_button_for(:reassign_user)).to eq(
            %(<a id="action--reassign-case" class="button" \
href="/cases/#{@case.id}/assignments/select_team?assignment_ids=#{@assignments.first.id}%2B#{@assignments.last.id}">Change team member</a>),
          )
        end
      end

      context "when there are no assignments for this users teams" do
        it "returns an empty string" do
          @case = create(:accepted_case)
          @assignments = []
          expect(action_button_for(:reassign_user)).to eq("")
        end
      end
    end

    context "when event == :upload_response_and_approve" do
      it "generates HTML that links to the " do
        @case = create(:pending_dacu_clearance_case)
        expect(action_button_for(:upload_response_and_approve))
          .to eq(
            "<a id=\"action--upload-approve\" class=\"button\" href=\"/cases/#{@case.id}/responses/new/upload_response_and_approve\">Upload response and clear</a>",
          )
      end
    end
  end

  describe "#case_uploaded_request_files_class" do
    before do
      @case = create(:case)
    end

    it "returns nil when case has no errors on uploaded_request_files" do
      expect(case_uploaded_request_files_class).to be_nil
    end

    it "returns error class when case has errors on uploaded_request_files" do
      @case.errors.add(:uploaded_request_files, :blank)
      expect(case_uploaded_request_files_class).to eq "error"
    end
  end

  describe "#case_uploaded_request_files_id" do
    before do
      @case = create(:case)
    end

    it "returns nil when case has no errors on uploaded_request_files" do
      expect(case_uploaded_request_files_id).to be_nil
    end

    it "returns error id when case has errors on uploaded_request_files" do
      @case.errors.add(:uploaded_request_files, :blank)
      expect(case_uploaded_request_files_id)
        .to eq "error_case_uploaded_request_files"
    end
  end

  describe "#action_links_for_allowed_events" do
    let(:policy_double) do
      double "Pundit::Policy",
             one?: true,
             two?: false,
             three?: true
    end

    it "generates links for allowed events" do
      @case = :case
      allow_any_instance_of(described_class).to receive(:policy).with(:case).and_return(policy_double)
      allow_any_instance_of(described_class).to receive(:action_link_for_one).with(:case).and_return("link_one")
      allow_any_instance_of(described_class).to receive(:action_link_for_three).with(:case).and_return("link_three")
      links = action_links_for_allowed_events(@case, :one, :two, :three)
      expect(links).to eq %w[link_one link_three]
    end
  end

  describe "#request_details_html" do
    it "generates html markup" do
      kase = instance_double(Case::Base, subject: "Once upon a time...", name: "Ray Gunn", type: "Case::FOI::Standard")
      request_details = request_details_html(kase)
      expect(request_details).to eq '<strong class="strong">Once upon a time... </strong><div class="data-detail">Ray Gunn</div>'
    end
  end

  describe "#case_link_with_hash" do
    let(:kase) { double "case", id: 25, number: "180425001" }

    context "when query hash instance variable exists" do
      context "and page parameters exists" do
        it "shows link with hash and position parameters" do
          expected_link = "<a href=\"/cases/25?pos=35\"><span class=\"visually-hidden\">Case number </span>180425001</a>"
          expect(case_link_with_hash(kase, :number, 2, 14)).to eq expected_link
        end
      end

      context "and page number does not exist" do
        it "shows link with hash and position parameters based on page 1" do
          expected_link = "<a href=\"/cases/25?pos=15\"><span class=\"visually-hidden\">Case number </span>180425001</a>"
          expect(case_link_with_hash(kase, :number, "", 14)).to eq expected_link
        end
      end
    end
  end

  describe "#case_details_links" do
    it "adds a link to edit case details if permitted" do
      kase = create(:case_being_drafted)
      user = find_or_create(:disclosure_bmt_user)
      result = case_details_links(kase, user)

      expect(result).to eq link_to(
        "Edit case details",
        "/cases/fois/#{kase.id}/edit",
        class: "secondary-action-link",
      )
    end

    it "adds a link to edit closure details if permitted" do
      kase = create(:closed_sar)
      user = find_or_create(:disclosure_bmt_user)
      result = case_details_links(kase, user)

      edit_case_link = link_to(
        "Edit case details",
        "/cases/sars/#{kase.id}/edit",
        class: "secondary-action-link",
      )

      edit_closure_link = link_to(
        "Edit closure details",
        "/cases/sars/#{kase.id}/edit_closure",
        class: "secondary-action-link",
      )
      expect(result).to eq "#{edit_case_link}#{edit_closure_link}"
    end
  end

  describe "#case_details_for_link_type" do
    it "returns case-details for empty link type" do
      expect(case_details_for_link_type(nil)).to eq "case-details"
    end

    it "returns original-case-details for original link types" do
      expect(case_details_for_link_type("original")).to eq "original-case-details"
    end
  end

  describe "#download_csv_link" do
    let(:base_path)     { "/cases/open" }
    let(:param_path)    { "/cases/open?page=3&type=foi" }

    context "with no query params" do
      it "returns link for csv without query params" do
        expect(download_csv_link(base_path)).to eq '<a href="/cases/open.csv">Download cases</a>'
      end
    end

    context "with query params" do
      it "returns link for csv with query params" do
        expect(download_csv_link(param_path)).to eq '<a href="/cases/open.csv?page=3&amp;type=foi">Download cases</a>'
      end
    end

    context "with report param" do
      it "returns link for csv with report param" do
        expect(download_csv_link(param_path, "r000")).to eq '<a href="/cases/open.csv?page=3&amp;type=foi&amp;report=r000">Download cases</a>'
      end
    end

    context "with custom link name" do
      it "returns link with specific name for display" do
        expect(download_csv_link(param_path, "r000", "test link")).to eq '<a href="/cases/open.csv?page=3&amp;type=foi&amp;report=r000">test link</a>'
      end
    end
  end

  describe "#show_escalation_deadline?" do
    context "when case is not an Offender SAR" do
      it "is false when escalation_deadline is not available" do
        kase = MockCase.new(
          has_attribute: false,
          within_escalation_deadline: true,
          is_offender_sar: false,
          is_offender_sar_complaint: false,
        )
        expect(show_escalation_deadline?(kase)).to eq false
      end

      it "is false when case is not within deadline" do
        kase = MockCase.new(
          has_attribute: true,
          within_escalation_deadline: false,
          is_offender_sar: false,
          is_offender_sar_complaint: false,
        )
        expect(show_escalation_deadline?(kase)).to eq false
      end

      it "is true when case is within escalation deadline" do
        kase = MockCase.new(
          has_attribute: true,
          within_escalation_deadline: true,
          is_offender_sar: false,
          is_offender_sar_complaint: false,
        )
        expect(show_escalation_deadline?(kase)).to eq true
      end
    end

    context "when case is an Offender SAR" do
      it "is always false" do
        kase = MockCase.new(
          has_attribute: true,
          within_escalation_deadline: true,
          is_offender_sar: true,
          is_offender_sar_complaint: false,
        )
        expect(show_escalation_deadline?(kase)).to eq false
      end
    end

    context "when case is an Offender SAR Complaint" do
      it "is always false" do
        kase = MockCase.new(
          has_attribute: true,
          within_escalation_deadline: true,
          is_offender_sar: false,
          is_offender_sar_complaint: true,
        )
        expect(show_escalation_deadline?(kase)).to eq false
      end
    end
  end

  describe "#choose_cover_page_id_number" do
    it "returns upcased PNC number when there is no prison number or it is a blank string" do
      prison_number = ""
      prison_number_2 = nil
      pnc_number = "PncTest1"

      output = choose_cover_page_id_number(prison_number, pnc_number)
      output_2 = choose_cover_page_id_number(prison_number_2, pnc_number)
      expect(output).to eq "PNCTEST1"
      expect(output_2).to eq "PNCTEST1"
    end

    it "returns upcased prison number if it is not blank or empty" do
      prison_number = "PrisonNum1"
      pnc_number = "PncTest1"
      output = choose_cover_page_id_number(prison_number, pnc_number)
      expect(output).to eq "PRISONNUM1"
    end

    it "only returns the first pnc number if more than one is available" do
      prison_number = ""
      pnc_number = "PncTest1, PncTest2, PncTest3"
      output = choose_cover_page_id_number(prison_number, pnc_number)
      expect(output).to eq "PNCTEST1"
    end

    it "only returns the first prison number if more than one is available" do
      prison_number = "PrisonNum1, PrisonNum2, PrisonNum3"
      pnc_number = "PncTest1, PncTest2, PncTest3"
      output = choose_cover_page_id_number(prison_number, pnc_number)
      expect(output).to eq "PRISONNUM1"
    end
  end

  describe "#sort_correspondence_types_for_display" do
    it "sorts correspondence types by their #display_order" do
      ct1 = build_stubbed(:correspondence_type, display_order: 0)
      ct2 = build_stubbed(:correspondence_type, display_order: 1)
      ct3 = build_stubbed(:correspondence_type, display_order: 2)

      result = sort_correspondence_types_for_display([ct3, ct1, ct2])
      expect(result.first).to be(ct1)
      expect(result.last).to be(ct3)
    end

    it "does not sort if members of collection have nil #display_order" do
      ct1 = build_stubbed(:correspondence_type, display_order: nil)
      ct2 = build_stubbed(:correspondence_type, display_order: nil)
      ct3 = build_stubbed(:correspondence_type, display_order: 2)

      result = sort_correspondence_types_for_display([ct3, ct1, ct2])
      expect(result.first).to be(ct3)
      expect(result.last).to be(ct2)
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
