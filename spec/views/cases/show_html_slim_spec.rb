require 'rails_helper'


describe 'cases/show.html.slim', type: :view do
  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  #rubocop:disable Metrics/MethodLength
  def setup_policies(policies)
    policy_names = [
      :assignments_execute_reassign_user?,
      :can_remove_attachment?,
      :can_respond?,
      :can_add_attachment?,
      :can_accept_or_reject_approver_assignment?,
      :can_view_attachments?,
      :can_add_message_to_case?,
      :destroy_case?,
      :destroy_case_link?,
      :execute_response_approval?,
      :extend_sar_deadline?,
      :extend_for_pit?,
      :remove_clearance?,
      :remove_pit_extension?,
      :remove_sar_deadline_extension?,
      :request_further_clearance?,
      :new_case_link?,
      :upload_responses?,
      :upload_responses_for_approve?,
      :upload_responses_for_flagged?,
      :upload_responses_for_redraft?
    ]


    if (policies.keys - policy_names).any?
      raise NameError,
            "unknown policy/ies: #{(policies.keys - policy_names).join(', ')}"
    end

    policy_names.each do |policy_name|
      unless policies.key? policy_name
      end
      allow(policy).to receive(policy_name).and_return policies[policy_name]
    end
  end
  #rubocop:enable Metrics/MethodLength

  let(:case_pending_dacu_clearance)       { create(:pending_dacu_clearance_case).decorate }
  let(:case_being_drafted)                { create(:case_being_drafted, :extended_for_pit).decorate }
  let(:case_being_drafted_flagged)        { create(:case_being_drafted, :flagged, :dacu_disclosure).decorate }
  let(:case_with_response)                { create(:case_with_response).decorate }
  let(:upheld_closed_sar_ico_appeal)      { create(:closed_ico_sar_case).decorate }
  let(:overturned_closed_sar_ico_appeal)  { create(:closed_ico_sar_case, :overturned_by_ico).decorate }

  let(:policy) do
    instance_double('Pundit::Policy').tap do |p|
      allow(view).to receive(:policy).and_return(p)
    end
  end

  let(:manager)   { create :manager }
  let(:responder) { find_or_create :foi_responder }
  let(:approver)  { create :approver }

  before do
    assign(:permitted_events, [])
    assign(:filtered_permitted_events, [])
    assign(:case_transitions, [])
  end

  subject do
    render
    cases_show_page.load(rendered)
    response
  end

  context 'with an unflagged case being drafted but no responses' do
    before do
      assign(:case, case_being_drafted)
    end

    context 'as a manager' do
      before do
        login_as manager
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false
      end

      it { should_not have_rendered 'cases/_case_attachments'}
    end

    context 'as an approver' do
      before do
        login_as approver
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false
      end

      it { should_not have_rendered 'cases/_case_attachments'}
    end

    context 'as a responder' do
      before do
        login_as responder
        setup_policies can_remove_attachment?: true,
                       can_add_attachment?: true,
                       can_accept_or_reject_approver_assignment?: false
      end

      it { should_not have_rendered 'cases/_case_attachments'}
    end
  end

  context 'with an unflagged case being drafted with responses' do
    before do
      assign(:case, case_with_response)
    end

    context 'as a manager' do
      before do
        login_as manager
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: false,
                       remove_clearance?: false
      end

      it { should_not have_rendered 'cases/_case_attachments'}
    end

    context 'as an approver' do
      before do
        login_as approver
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: false
      end

      it { should_not have_rendered 'cases/_case_attachments'}
    end

    context 'as a responder' do
      before do
        login_as responder
        setup_policies can_remove_attachment?: true,
                       can_add_attachment?: true,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true
      end

      it { should have_rendered 'cases/_case_attachments'}
    end
  end

  context 'with a flagged case being drafted' do
    before do
      assign(:case, case_being_drafted_flagged)
    end

    context 'as a manager' do
      before do
        login_as manager
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true
      end

      it { should_not have_rendered 'cases/_case_attachments'}
    end

    context 'as a responder' do
      before do
        login_as responder
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true
      end

      it { should_not have_rendered 'cases/_case_attachments'}
    end

    context 'as an approver' do
      before do
        login_as approver
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true
      end

      it { should_not have_rendered 'cases/_case_attachments'}
    end
  end

  context 'with a flagged case pending dacu clearance' do
    before do
      assign(:case, case_pending_dacu_clearance)
    end

    context 'as a manager' do
      before do
        login_as manager
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true,
                       remove_clearance?: false
      end

      it { should have_rendered 'cases/_case_attachments'}
    end

    context 'as a responder' do
      before do
        login_as responder
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true,
                       remove_clearance?: false
      end

      it { should have_rendered 'cases/_case_attachments'}
    end

    context 'as an approver' do
      before do
        login_as approver
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true,
                       request_further_clearance?: true,
                       remove_clearance?: true
      end

      it { should have_rendered 'cases/_case_attachments'}
    end
  end

  describe 'link to extend case for pit' do
    before do
      assign(:case, case_being_drafted)
    end

    subject do
      render
      cases_show_page.load(rendered)
      cases_show_page
    end

    context 'for a user that has permission to do the action' do
      before do
        login_as manager
        setup_policies extend_for_pit?: true,
                       remove_pit_extension?: true
      end

      it { should have_extend_for_pit_action }
      it { should have_remove_pit_extension_action }
    end

    context 'for a user that does not have permission to do the action' do
      before do
        login_as responder
        setup_policies extend_for_pit?: false
      end

      it { should_not have_extend_for_pit_action }
    end
  end

  describe 'link to create new overturned ico case' do

    before(:each) do
      setup_policies assignments_execute_reassign_user?: false,
                     remove_clearance?: false,
                     execute_response_approval?: false,
                     upload_responses?: false,
                     upload_responses_for_approve?: false,
                     upload_responses_for_redraft?: false

    end

    context 'when permitted events include create_overturned' do
      it 'shows button' do
        assign(:case, overturned_closed_sar_ico_appeal)
        assign(:permitted_events, [:create_overturned])
        assign(:filtered_permitted_events, [:create_overturned] )
        login_as manager
        render
        cases_show_page.load(rendered)
        expect(cases_show_page.actions).to have_create_overturned
      end
    end

    context 'when permitted events does not include create overturned' do
      it 'does not show button' do
        assign(:case, overturned_closed_sar_ico_appeal)
        assign(:permitted_events, [])
        assign(:filtered_permitted_events, [] )
        login_as manager
        render
        cases_show_page.load(rendered)
        expect(cases_show_page.actions).not_to have_create_overturned
      end
    end
  end

  describe 'extending a SAR case' do
    context 'before it is extended' do
      let(:sar) { create(:approved_sar).decorate }

      before do
        assign(:case, sar)
        assign(:permitted_events, [:extend_sar_deadline])
        assign(:filtered_permitted_events, [:extend_sar_deadline])

        setup_policies(
          extend_sar_deadline?: true,
          remove_sar_deadline_extension?: false
        )
      end

      context 'as a manager' do
        it 'shows extend action' do
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).to have_extend_sar_deadline
          expect(cases_show_page.actions).not_to have_remove_sar_deadline_extension
        end
      end
    end

    context 'after it is extended' do
      let(:sar) {
        extended_sar = create(:extended_deadline_sar)
        extended_sar.external_deadline += 60.days
        extended_sar.decorate
      }

      before do
        assign(:case, sar)
        assign(:permitted_events, [:remove_sar_deadline_extension])
        assign(:filtered_permitted_events, [:remove_sar_deadline_extension])

        setup_policies(
          extend_sar_deadline?: false,
          remove_sar_deadline_extension?: true
        )
      end

      context 'as a manager' do
        it 'shows remove action' do
          login_as manager
          render
          cases_show_page.load(rendered)

          expect(cases_show_page.actions).not_to have_extend_sar_deadline
          expect(cases_show_page.actions).to have_remove_sar_deadline_extension
        end
      end
    end
  end
end
