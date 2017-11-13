require 'rails_helper'


describe 'cases/show.html.slim', type: :view do
  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  def setup_policies(policies)
    policy_names = [
      :can_remove_attachment?,
      :can_add_attachment?,
      :can_accept_or_reject_approver_assignment?,
      :can_view_attachments?,
      :can_add_message_to_case?,
      :destroy_case?,
      :extend_for_pit?,
      :request_further_clearance?
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

  let(:case_pending_dacu_clearance) { create(:pending_dacu_clearance_case)
                                        .decorate }
  let(:case_being_drafted) { create(:case_being_drafted).decorate }
  let(:case_being_drafted_flagged) { create(:case_being_drafted, :flagged)
                                       .decorate }
  let(:case_with_response) { create(:case_with_response).decorate }
  let(:policy) do
    instance_double('Pundit::Policy').tap do |p|
      allow(view).to receive(:policy).and_return(p)
    end
  end
  let(:manager)   { create :manager }
  let(:responder) { create :responder }
  let(:approver)  { create :approver }

  before do
    assign(:permitted_events, [])
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
                       can_accept_or_reject_approver_assignment?: false,
                       request_further_clearance?: true
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
                       can_view_attachments?: false
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
                       can_view_attachments?: true
      end

      it { should have_rendered 'cases/_case_attachments'}
    end

    context 'as a responder' do
      before do
        login_as responder
        setup_policies can_remove_attachment?: false,
                       can_add_attachment?: false,
                       can_accept_or_reject_approver_assignment?: false,
                       can_view_attachments?: true
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
                       request_further_clearance?: true
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
        setup_policies extend_for_pit?: true
      end

      it { should have_extend_for_pit_action }
    end

    context 'for a user that does not have permission to do the action' do
      before do
        login_as responder
        setup_policies extend_for_pit?: false
      end

      it { should_not have_extend_for_pit_action }
    end
  end
end
