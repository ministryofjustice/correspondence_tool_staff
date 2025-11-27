require "rails_helper"

describe "cases/show.html.slim", type: :view do
  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  def setup_policies(policies)
    policy_names = %i[
      approve?
      assignments_execute_reassign_user?
      can_remove_attachment?
      can_respond?
      can_add_attachment?
      can_accept_or_reject_approver_assignment?
      can_view_attachments?
      can_add_message_to_case?
      can_stop_the_clock?
      destroy_case?
      destroy_case_link?
      extend_sar_deadline?
      extend_for_pit?
      new_case_link?
      remove_clearance?
      remove_pit_extension?
      remove_sar_deadline_extension?
      request_further_clearance?
      upload_responses?
      upload_response_and_approve?
      upload_responses_for_flagged?
      upload_response_and_return_for_redraft?
      mark_as_waiting_for_data
      mark_as_ready_for_vetting
      mark_as_vetting_in_progress
      mark_as_ready_to_copy
      mark_as_ready_to_dispatch
      close
      can_add_note_to_case?
      can_record_data_request?
      can_upload_request_attachment?
    ]

    if (policies.keys - policy_names).any?
      raise NameError,
            "unknown policy/ies: #{(policies.keys - policy_names).join(', ')}"
    end

    policy_names.each do |policy_name|
      allow(policy).to receive(policy_name).and_return policies[policy_name]
    end
  end

  subject do
    render
    cases_show_page.load(rendered)
    response
  end

  let(:case_pending_dacu_clearance)       { create(:pending_dacu_clearance_case).decorate }
  let(:case_being_drafted)                { create(:case_being_drafted, :extended_for_pit).decorate }
  let(:case_being_drafted_flagged)        { create(:case_being_drafted, :flagged, :dacu_disclosure).decorate }
  let(:case_with_response)                { create(:case_with_response).decorate }
  let(:upheld_closed_sar_ico_appeal)      { create(:closed_ico_sar_case).decorate }
  let(:overturned_closed_sar_ico_appeal)  { create(:closed_ico_sar_case, :overturned_by_ico).decorate }

  let(:policy) do
    instance_double("Pundit::Policy").tap do |p|
      allow(view).to receive(:policy).and_return(p)
    end
  end

  let(:manager)   { create :manager }
  let(:responder) { find_or_create :foi_responder }
  let(:approver)  { create :approver }

  # Convenience fixture that allows us to control when the page is rendered,
  # useful as the subject of tests.
  let(:rendered_page) do
    render
    cases_show_page.load(rendered)
    cases_show_page
  end

  before do
    assign(:permitted_events, [])
    assign(:filtered_permitted_events, [])
    assign(:case_transitions, [])
  end

  context "with an unflagged case being drafted but no responses" do
    before do
      assign(:case, case_being_drafted)
    end

    context "when a manager" do
      before do
        login_as manager
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false
      end

      it { is_expected.not_to have_rendered "cases/_case_attachments" }
    end

    context "when an approver" do
      before do
        login_as approver
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false
      end

      it { is_expected.not_to have_rendered "cases/_case_attachments" }
    end

    context "when a responder" do
      before do
        login_as responder
        setup_policies can_remove_attachment?: true,
                       can_add_attachment?: true,
                       can_accept_or_reject_approver_assignment?: false
      end

      it { is_expected.not_to have_rendered "cases/_case_attachments" }
    end
  end

  context "with an unflagged case being drafted with responses" do
    before do
      assign(:case, case_with_response)
    end

    context "when a manager" do
      before do
        login_as manager
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: false,
                       remove_clearance?: false
      end

      it { is_expected.not_to have_rendered "cases/_case_attachments" }
    end

    context "when an approver" do
      before do
        login_as approver
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: false
      end

      it { is_expected.not_to have_rendered "cases/_case_attachments" }
    end

    context "when a responder" do
      before do
        login_as responder
        setup_policies can_remove_attachment?: true,
                       can_add_attachment?: true,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true
      end

      it { is_expected.to have_rendered "cases/_case_attachments" }
    end
  end

  context "with a flagged case being drafted" do
    before do
      assign(:case, case_being_drafted_flagged)
    end

    context "when a manager" do
      before do
        login_as manager
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true
      end

      it { is_expected.not_to have_rendered "cases/_case_attachments" }
    end

    context "when a responder" do
      before do
        login_as responder
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true
      end

      it { is_expected.not_to have_rendered "cases/_case_attachments" }
    end

    context "when an approver" do
      before do
        login_as approver
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true
      end

      it { is_expected.not_to have_rendered "cases/_case_attachments" }
    end
  end

  context "with a flagged case pending dacu clearance" do
    before do
      assign(:case, case_pending_dacu_clearance)
    end

    context "when a manager" do
      before do
        login_as manager
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true,
                       remove_clearance?: false
      end

      it { is_expected.to have_rendered "cases/_case_attachments" }
    end

    context "when a responder" do
      before do
        login_as responder
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true,
                       remove_clearance?: false
      end

      it { is_expected.to have_rendered "cases/_case_attachments" }
    end

    context "when an approver" do
      before do
        login_as approver
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true,
                       request_further_clearance?: true,
                       remove_clearance?: true
      end

      it { is_expected.to have_rendered "cases/_case_attachments" }
    end
  end

  describe "page actions" do
    subject(:page) { rendered_page.actions }

    let(:kase) { create(:foi_case) }

    describe "upload response button" do
      before do
        login_as approver
        assign(:case, kase.decorate)
      end

      context "when upload_responses policy is permitted" do
        before do
          assign(:filtered_permitted_events, [:add_responses])
          setup_policies upload_responses?: true
        end

        it { is_expected.to have_upload_response }

        it "links to the path for upload_responses" do
          expect(page.upload_response["href"])
            .to eq new_case_responses_path(kase, response_action: :upload_responses)
        end
      end

      context "when upload_responses policy is NOT permitted" do
        before do
          assign(:filtered_permitted_events, [:some_other_action])
          setup_policies upload_responses?: false
        end

        it { is_expected.not_to have_upload_response }
      end
    end

    describe "upload response and approve button" do
      before do
        login_as approver
        assign(:case, kase.decorate)
      end

      context "when upload_response_and_approve policy is permitted" do
        before do
          assign(:filtered_permitted_events, [:upload_response_and_approve])
          setup_policies upload_response_and_approve?: true
        end

        it { is_expected.to have_upload_approve }

        it "links to the path for upload_responses" do
          expect(page.upload_approve["href"])
            .to eq new_case_responses_path(kase, response_action: :upload_response_and_approve)
        end
      end

      context "when upload_response_and_approve policy is NOT permitted" do
        before do
          assign(:filtered_permitted_events, [:some_other_action])
          setup_policies upload_response_and_approve?: false
        end

        it { is_expected.not_to have_upload_approve }
      end
    end

    describe "upload response and return for redraft button" do
      before do
        login_as approver
        assign(:case, kase.decorate)
      end

      context "when upload_response_and_return_for_redraft policy is permitted" do
        before do
          assign(:filtered_permitted_events, [:upload_response_and_return_for_redraft?])
          setup_policies upload_response_and_return_for_redraft?: true
        end

        it { is_expected.to have_upload_redraft }

        it "links to the path for upload_responses" do
          expect(page.upload_redraft["href"])
            .to eq new_case_responses_path(kase, response_action: :upload_response_and_return_for_redraft)
        end
      end

      context "when upload_response_and_return_for_redraft policy is NOT permitted" do
        before do
          assign(:filtered_permitted_events, [:some_other_action])
          setup_policies upload_response_and_return_for_redraft?: false
        end

        it { is_expected.not_to have_upload_redraft }
      end
    end
  end

  describe "button to extend case for pit" do
    subject { rendered_page }

    before do
      assign(:case, case_being_drafted)
    end

    context "with a user that has permission to do the action" do
      before do
        login_as manager
        setup_policies extend_for_pit?: true,
                       remove_pit_extension?: true
      end

      it { is_expected.to have_extend_for_pit_action }
      it { is_expected.to have_remove_pit_extension_action }
    end

    context "with a user that does not have permission to do the action" do
      before do
        login_as responder
        setup_policies extend_for_pit?: false
      end

      it { is_expected.not_to have_extend_for_pit_action }
    end
  end

  describe "link to create new overturned ico case" do
    before do
      setup_policies assignments_execute_reassign_user?: false,
                     remove_clearance?: false,
                     approve?: false,
                     upload_responses?: false,
                     upload_response_and_approve?: false,
                     upload_response_and_return_for_redraft?: false
    end

    context "when permitted events include create_overturned" do
      it "shows button" do
        assign(:case, overturned_closed_sar_ico_appeal)
        assign(:permitted_events, [:create_overturned])
        assign(:filtered_permitted_events, [:create_overturned])
        login_as manager
        render
        cases_show_page.load(rendered)
        expect(cases_show_page.actions).to have_create_overturned
      end
    end

    context "when permitted events does not include create overturned" do
      it "does not show button" do
        assign(:case, overturned_closed_sar_ico_appeal)
        assign(:permitted_events, [])
        assign(:filtered_permitted_events, [])
        login_as manager
        render
        cases_show_page.load(rendered)
        expect(cases_show_page.actions).not_to have_create_overturned
      end
    end
  end

  describe "extending a SAR case" do
    context "and before it is extended" do
      let(:sar) { create(:approved_sar).decorate }

      before do
        assign(:case, sar)
        assign(:permitted_events, [:extend_sar_deadline])
        assign(:filtered_permitted_events, [:extend_sar_deadline])

        setup_policies(
          extend_sar_deadline?: true,
          remove_sar_deadline_extension?: false,
        )
      end

      context "when a manager" do
        it "shows extend action" do
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page).to have_extend_sar_deadline
          expect(cases_show_page).not_to have_remove_sar_deadline_extension
        end
      end
    end

    context "and after it is extended" do
      let(:sar) do
        extended_sar = create(:sar_case, :extended_deadline_sar)
        extended_sar.external_deadline += 60.days
        extended_sar.decorate
      end

      before do
        assign(:case, sar)
        assign(:permitted_events, [:remove_sar_deadline_extension])
        assign(:filtered_permitted_events, [:remove_sar_deadline_extension])

        setup_policies(
          extend_sar_deadline?: false,
          remove_sar_deadline_extension?: true,
        )
      end

      context "when a manager" do
        it "shows remove action" do
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page).not_to have_extend_sar_deadline
          expect(cases_show_page).to have_remove_sar_deadline_extension
        end
      end
    end
  end

  describe "stopping a SAR case" do
    context "and before it is stopped" do
      let(:sar) { create(:approved_sar).decorate }

      before do
        assign(:case, sar)
        assign(:permitted_events, [:stop_the_clock])
        assign(:filtered_permitted_events, [:stop_the_clock])

        setup_policies(
          can_stop_the_clock?: true,
        )
      end

      context "when a manager" do
        it "shows stop the clock action" do
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page).to have_stop_the_clock
          expect(cases_show_page).not_to have_restart_the_clock
        end
      end
    end
  end

  describe "offender sar case" do
    let(:offender_sar_case) { create(:offender_sar_case).decorate }

    before do
      assign(:case, offender_sar_case)
      setup_policies(
        mark_as_waiting_for_data: true,
        mark_as_ready_for_vetting: true,
        mark_as_vetting_in_progress: true,
        mark_as_ready_to_dispatch: true,
        mark_as_ready_to_copy: true,
        close: true,
        can_add_note_to_case?: true,
        can_record_data_request?: true,
      )
    end

    context "when a manager" do
      describe "partials" do
        before do
          assign(:permitted_events, [:add_note_to_case])
          assign(:filtered_permitted_events, [:add_note_to_case])
          login_as manager
          render
          cases_show_page.load(rendered)
        end

        it { is_expected.not_to have_rendered "cases/_case_messages" }
        it { is_expected.to have_rendered "cases/offender_sar/_case_notes" }
        it { is_expected.to have_rendered "cases/offender_sar/_data_request_areas" }
      end

      context "when a case just created" do
        it "shows mark as waiting for data" do
          assign(:permitted_events, [:mark_as_waiting_for_data])
          assign(:filtered_permitted_events, [:mark_as_waiting_for_data])
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_mark_as_waiting_for_data
        end
      end

      context "when a case is waiting for data" do
        it "shows mark as ready for vetting" do
          assign(:permitted_events, [:mark_as_ready_for_vetting])
          assign(:filtered_permitted_events, [:mark_as_ready_for_vetting])
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_mark_as_ready_for_vetting
          expect(cases_show_page.data_request_areas.section_heading).to be_present
        end
      end

      context "when a case is ready for vetting" do
        it "shows mark as vetting in progress" do
          assign(:permitted_events, [:mark_as_vetting_in_progress])
          assign(:filtered_permitted_events, [:mark_as_vetting_in_progress])
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_mark_as_vetting_in_progress
        end
      end

      context "when a case is vetting in progress" do
        it "shows mark as ready to dispatch" do
          assign(:permitted_events, [:mark_as_ready_to_dispatch])
          assign(:filtered_permitted_events, [:mark_as_ready_to_dispatch])
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_mark_as_ready_to_dispatch
        end
      end

      context "when a case is ready to dispatch" do
        it "shows mark as ready to close" do
          assign(:permitted_events, [:mark_as_ready_to_copy])
          assign(:filtered_permitted_events, [:mark_as_ready_to_copy])
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_mark_as_ready_to_copy
        end
      end

      describe "record data request" do
        before do
          assign(:permitted_events, [:mark_as_waiting_for_data])
          assign(:filtered_permitted_events, [:mark_as_waiting_for_data])
          login_as manager
        end

        # Green button when no data requests have been recorded
        it "shows record data request button" do
          render
          cases_show_page.load(rendered)
          expect(cases_show_page.data_request_area_actions.record_data_request_area["class"]).to match(/button-tertiary/)
        end
      end

      describe "data requested section" do
        before do
          login_as manager
        end

        it "shows none message when case has no data requests" do
          assign(:case, offender_sar_case)
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.data_request_areas.none.text).to eq "No data requests recorded"
        end

        it "shows data requests as table rows" do
          new_offender_sar_case = create(:offender_sar_case).decorate

          2.times do
            new_offender_sar_case.data_request_areas.create(
              location: "The Location",
              data_request_area_type: "prison",
              user: manager,
            )
          end

          assign(:case, new_offender_sar_case)
          render
          cases_show_page.load(rendered)
          data_request_areas = cases_show_page.data_request_areas.rows

          expect(data_request_areas.size).to eq 3
          expect(data_request_areas.first.location.text).to eq "The Location"
          expect(data_request_areas.first.data_area.text).to eq "Prison"
          expect(data_request_areas.first.pages.text).to eq "0"
          expect(data_request_areas.first.show.text).to eq "View"
        end
      end
    end
  end

  describe "offender sar complaint" do
    let(:offender_sar_complaint) { create(:offender_sar_complaint).decorate }

    before do
      assign(:case, offender_sar_complaint)
      setup_policies(
        mark_as_waiting_for_data: true,
        mark_as_ready_for_vetting: true,
        mark_as_vetting_in_progress: true,
        mark_as_ready_to_dispatch: true,
        mark_as_ready_to_copy: true,
        close: true,
        can_add_note_to_case?: true,
        can_record_data_request?: true,
      )
    end

    context "when a manager" do
      context "with partials" do
        before do
          assign(:permitted_events, [:add_note_to_case])
          assign(:filtered_permitted_events, [:add_note_to_case])
          login_as manager
          render
          cases_show_page.load(rendered)
        end

        it { is_expected.not_to have_rendered "cases/_case_messages" }
        it { is_expected.to have_rendered "cases/offender_sar/_case_notes" }
        it { is_expected.to have_rendered "cases/offender_sar/_data_request_areas" }
      end

      context "when a case just created" do
        it "shows mark as waiting for data" do
          assign(:permitted_events, [:mark_as_waiting_for_data])
          assign(:filtered_permitted_events, [:mark_as_waiting_for_data])
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_mark_as_waiting_for_data
        end
      end

      context "when a case is waiting for data" do
        it "shows mark as ready for vetting" do
          assign(:permitted_events, [:mark_as_ready_for_vetting])
          assign(:filtered_permitted_events, [:mark_as_ready_for_vetting])
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_mark_as_ready_for_vetting
          expect(cases_show_page.data_request_areas.section_heading).to be_present
        end
      end

      context "when a case is ready for vetting" do
        it "shows mark as vetting in progress" do
          assign(:permitted_events, [:mark_as_vetting_in_progress])
          assign(:filtered_permitted_events, [:mark_as_vetting_in_progress])
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_mark_as_vetting_in_progress
        end
      end

      context "when a case is vetting in progress" do
        it "shows mark as ready to dispatch" do
          assign(:permitted_events, [:mark_as_ready_to_dispatch])
          assign(:filtered_permitted_events, [:mark_as_ready_to_dispatch])
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_mark_as_ready_to_dispatch
        end
      end

      context "when a case is ready to dispatch" do
        it "shows mark as ready to close" do
          assign(:permitted_events, [:mark_as_ready_to_copy])
          assign(:filtered_permitted_events, [:mark_as_ready_to_copy])
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_mark_as_ready_to_copy
        end
      end

      context "with record data request" do
        before do
          assign(:permitted_events, [:mark_as_waiting_for_data])
          assign(:filtered_permitted_events, [:mark_as_waiting_for_data])
          login_as manager
        end

        # Green button when no data requests have been recorded
        it "shows record data request button" do
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.data_request_area_actions.record_data_request_area["class"]).to match(/button-tertiary/)
        end
      end

      context "with data requested section" do
        before do
          login_as manager
        end

        it "shows none message when case has no data requests" do
          assign(:case, offender_sar_complaint)
          render
          cases_show_page.load(rendered)
          expect(cases_show_page.data_request_areas.none.text).to eq "No data requests recorded"
        end

        it "shows data requests as table rows" do
          new_offender_sar_complaint = create(:offender_sar_complaint).decorate

          2.times do
            new_offender_sar_complaint.data_request_areas.create(
              location: "The Location",
              data_request_area_type: "prison",
              user: manager,
            )
          end

          assign(:case, new_offender_sar_complaint)
          render
          cases_show_page.load(rendered)
          data_request_areas = cases_show_page.data_request_areas.rows

          expect(data_request_areas.size).to eq 3
          expect(data_request_areas.first.location.text).to eq "The Location"
          expect(data_request_areas.first.data_area.text).to eq "Prison"
          expect(data_request_areas.first.pages.text).to eq "0"
        end
      end
    end
  end
end
