require 'rails_helper'



# helper class to make example groups a bit more readable below
def event(event_name)
  CaseStateMachine.events[event_name]
end

RSpec.describe CaseStateMachine, type: :model do
  let(:kase)               { create :case }
  let(:state_machine) do
    CaseStateMachine.new(
      kase,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end
  let(:managing_team)      { create :managing_team }
  let(:manager)            { managing_team.managers.first }
  let(:responding_team)    { create :responding_team }
  let(:responder)          { responding_team.responders.first }
  let(:approving_team)     { create :approving_team }
  let(:approver)           { approving_team.approvers.first }
  let(:other_approver)     {
    create :approver, approving_team: approving_team
  }
  let(:new_case)           { create :case }
  let(:assigned_case)      { create :assigned_case,
                                 responding_team: responding_team }
  let(:assigned_flagged_case) { create :assigned_case, :flagged,
                                       responding_team: responding_team }
  let(:case_being_drafted) { create :case_being_drafted,
                                    responder: responder,
                                    responding_team: responding_team }
  let(:case_with_response) { create :case_with_response,
                                    responder: responder,
                                    responding_team: responding_team }
  let(:responded_case)     { create :responded_case,
                             responder: responder,
                             responding_team: responding_team }
  let(:closed_case)        { create :closed_case,
                             responder: responder,
                             responding_team: responding_team }

  let(:pending_dacu_clearance_case) { create :pending_dacu_clearance_case }
  let(:disclosure_specialist)       { create :disclosure_specialist }
  let(:team_dacu_disclosure)        { find_or_create :team_dacu_disclosure }

  context 'after transition' do
    let(:t1) { Time.now }
    let(:t2) { Time.now + 3.days }

    it 'stores current state and time of transition on the case record' do
      Timecop.freeze(t1) do
        expect(kase.current_state).to eq 'unassigned'
        expect(kase.last_transitioned_at).to eq t1
      end
      Timecop.freeze(t2) do
        kase.assign_responder(manager, responding_team)
      end
      expect(kase.current_state).to eq 'awaiting_responder'
      expect(kase.last_transitioned_at).to eq t2
    end
  end

  describe event(:assign_responder) do
    it { should transition_from(:unassigned).to(:awaiting_responder) }
    it { should require_permission(:can_assign_case?)
                  .using_options(user_id: manager.id)
                  .using_object(new_case) }
  end

  describe event(:flag_for_clearance) do
    it { should transition_from(:unassigned).to(:unassigned) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should require_permission(:can_flag_for_clearance?)
                  .using_options(user_id: manager.id)
                  .using_object(assigned_case) }
  end

  describe event(:unflag_for_clearance) do
    it { should transition_from(:unassigned).to(:unassigned) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should require_permission(:can_unflag_for_clearance?)
                  .using_options(user_id: manager.id)
                  .using_object(assigned_flagged_case) }
  end

  describe event(:accept_approver_assignment) do
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should transition_from(:responded).to(:responded) }
    it { should require_permission(:can_accept_or_reject_approver_assignment?)
                  .using_options(user_id: approver.id)
                  .using_object(kase) }
  end


  describe event(:unaccept_approver_assignment) do
    it { should transition_from(:unassigned).to(:unassigned) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should transition_from(:pending_dacu_clearance).to(:pending_dacu_clearance) }
    it { should require_permission(:can_unaccept_approval_assignment?)
            .using_options(user_id: approver.id)
            .using_object(kase) }
  end

  describe event(:reassign_approver) do
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:pending_dacu_clearance).to(:pending_dacu_clearance) }
    it { should require_permission(:can_reassign_approver?)
                  .using_options(user_id: other_approver.id)
                  .using_object(pending_dacu_clearance_case) }

  end

  describe event(:accept_responder_assignment) do
    it { should transition_from(:awaiting_responder).to(:drafting) }
    it { should require_permission(:can_accept_or_reject_responder_assignment?)
                  .using_options(user_id: responder.id)
                  .using_object(assigned_case) }
  end

  describe event(:reject_responder_assignment) do
    it { should transition_from(:awaiting_responder).to(:unassigned) }
    it { should require_permission(:can_accept_or_reject_responder_assignment?)
                  .using_options(user_id: responder.id)
                  .using_object(assigned_case) }
  end

  describe event(:add_responses) do
    it { should transition_from(:drafting).to(:awaiting_dispatch) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should require_permission(:can_add_attachment?)
                  .using_options(user_id: responder.id)
                  .using_object(case_being_drafted) }
  end

  describe event(:add_response_to_flagged_case) do
    it { should transition_from(:drafting).to(:pending_dacu_clearance) }
    it { should require_permission(:can_add_attachment_to_flagged_case?)
                  .using_options(user_id: responder.id)
                  .using_object(case_being_drafted) }
  end

  describe event(:remove_response) do
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should require_permission(:can_remove_attachment?)
                  .using_options(user_id: responder.id)
                  .using_object(case_with_response) }
  end

  describe event(:remove_last_response) do
    it { should transition_from(:awaiting_dispatch).to(:drafting) }
    it { should require_permission(:can_remove_attachment?)
                  .using_options(user_id: responder.id)
                  .using_object(case_with_response) }
  end

  describe event(:respond) do
    it { should transition_from(:awaiting_dispatch).to(:responded) }
    it { should require_permission(:can_respond?)
                  .using_options(user_id: responder.id)
                  .using_object(case_with_response) }
  end

  describe event(:approve) do
    it { should transition_from(:pending_dacu_clearance).to :awaiting_dispatch}
    it { should require_permission(:can_approve_case?)
                  .using_options(user_id: approver.id)
                  .using_object(pending_dacu_clearance_case)
    }
  end

  describe event(:upload_response_and_approve) do
    it { should transition_from(:pending_dacu_clearance).to :awaiting_dispatch}
    it { should require_permission(:can_upload_response_and_approve?)
                  .using_options(user_id: approver.id)
                  .using_object(pending_dacu_clearance_case)
    }
  end

  describe event(:upload_response_and_return_for_redraft) do
    it { should transition_from(:pending_dacu_clearance).to :drafting }
    it { should require_permission(:can_upload_response_and_approve?)
                  .using_options(user_id: approver.id)
                  .using_object(pending_dacu_clearance_case)
    }
  end

  describe event(:close) do
    it { should transition_from(:responded).to(:closed) }
    it { should require_permission(:can_close_case?)
                  .using_options(user_id: manager.id)
                  .using_object(responded_case) }
  end

  describe event(:add_message_to_case) do
    it { should transition_from(:unassigned).to(:unassigned) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should transition_from(:pending_dacu_clearance).to(:pending_dacu_clearance) }
    it { should transition_from(:responded).to(:responded) }
    it { should require_permission(:can_add_message_to_case?)
                  .using_options(user_id: manager.id)
                  .using_object(responded_case) }
  end

  describe 'trigger assign_responder!' do
    it 'triggers an assign_responder event' do
      expect do
        new_case.state_machine.assign_responder! manager,
                                                 managing_team,
                                                 responding_team
      end.to trigger_the_event(:assign_responder)
               .on_state_machine(new_case.state_machine)
               .with_parameters user_id:            manager.id,
                                managing_team_id:   managing_team.id,
                                responding_team_id: responding_team.id
    end
  end

  describe 'trigger flag_for_clearance!' do
    it 'triggers a flag_for_clearance event' do
      expect do
        assigned_case.state_machine.flag_for_clearance! manager,
                                                        managing_team,
                                                        approving_team
      end
        .to trigger_the_event(:flag_for_clearance)
              .on_state_machine(assigned_case.state_machine)
              .with_parameters user_id: manager.id,
                               managing_team_id: managing_team.id,
                               approving_team_id: approving_team.id
    end
  end

  describe 'trigger accept_approver_assignment!' do
    it 'triggers an accept_approver_assignment event' do
      expect do
        assigned_case.state_machine.accept_approver_assignment! approver,
                                                                approving_team
      end.to trigger_the_event(:accept_approver_assignment)
               .on_state_machine(assigned_case.state_machine)
               .with_parameters(user_id: approver.id,
                                approving_team_id: approving_team.id)
    end
  end


  describe 'trigger unaccept_approver_assignment!' do
    it 'triggers unaccept_approver_assignment event' do
      expect {
        assigned_case.state_machine.unaccept_approver_assignment! approver, approving_team
      }.to trigger_the_event(:unaccept_approver_assignment)
              .on_state_machine(assigned_case.state_machine)
              .with_parameters(user_id: approver.id, approving_team_id: approving_team.id)
    end
  end

  describe 'trigger accept_responder_assignment!' do
    it 'triggers an accept_responder_assignment event' do
      expect do
        assigned_case.state_machine.accept_responder_assignment! responder,
                                                                 responding_team
      end.to trigger_the_event(:accept_responder_assignment)
               .on_state_machine(assigned_case.state_machine)
               .with_parameters(user_id: responder.id,
                                responding_team_id: responding_team.id)
    end
  end

  describe 'trigger a reassign_approver' do
    let(:kase) { pending_dacu_clearance_case }
    let(:new_disclosure_specialist) { create :disclosure_specialist }

    it 'triggers a reassign_approver'do
      expect {
        kase.state_machine.reassign_approver!(new_disclosure_specialist,
                                              disclosure_specialist,
                                              team_dacu_disclosure)
      }.to trigger_the_event(:reassign_approver)
                .on_state_machine(kase.state_machine)
                .with_parameters(user_id: new_disclosure_specialist.id,
                                 original_user_id: disclosure_specialist.id,
                                 approving_team_id: team_dacu_disclosure.id)
    end

    it 'adds a transition history record' do
      kase.state_machine.reassign_approver!(new_disclosure_specialist,
                                            disclosure_specialist,
                                            team_dacu_disclosure)
      transition = kase.reload.transitions.last
      expect(transition.event).to eq 'reassign_approver'
      expect(transition.to_state).to eq 'pending_dacu_clearance'
      expect(transition.user_id).to eq new_disclosure_specialist.id
      expect(transition.original_user_id).to eq disclosure_specialist.id
      expect(transition.approving_team_id).to eq team_dacu_disclosure.id
    end
  end

  describe 'trigger reject_responder_assignment!' do
    let(:message) { |example| "test #{example.description}" }

    it 'triggers a reject_responder_assignment event' do
      expect do
        assigned_case.state_machine.reject_responder_assignment! responder,
                                                                 responding_team,
                                                                 message
      end.to trigger_the_event(:reject_responder_assignment)
               .on_state_machine(assigned_case.state_machine)
               .with_parameters(user_id: responder.id,
                                responding_team_id: responding_team.id,
                                message: message)
    end
  end

  describe 'trigger add_responses!' do
    let(:filenames) { ['file1.pdf', 'file2.pdf'] }

    it 'triggers an add_responses event' do
      expect do
        case_being_drafted.state_machine.add_responses! responder,
                                                        responding_team,
                                                        filenames
      end.to trigger_the_event(:add_responses)
               .on_state_machine(case_being_drafted.state_machine)
               .with_parameters(user_id: responder.id,
                                responding_team_id: responding_team.id,
                                filenames: filenames)
    end
  end

  describe 'trigger remove_response!' do
    let(:filenames) { ['file1.pdf'] }

    context 'no attachments left' do
      it 'triggers a remove_last_response event' do
        expect do
          case_with_response.state_machine.remove_response! responder,
                                                            responding_team,
                                                            filenames,
                                                            0
        end.to trigger_the_event(:remove_last_response)
                 .on_state_machine(case_with_response.state_machine)
                 .with_parameters(user_id: responder.id,
                                  responding_team_id: responding_team.id,
                                  filenames: filenames)
      end
    end

    context 'some attachments left' do
      it 'triggers a remove_last_response event' do
      expect do
        case_with_response.state_machine.remove_response!(
          responder,
          responding_team,
          filenames,
          1,
        )
      end.to trigger_the_event(:remove_response)
               .on_state_machine(case_with_response.state_machine)
               .with_parameters(user_id: responder.id,
                                responding_team_id: responding_team.id,
                                filenames: filenames)
      end
    end
  end

  describe 'trigger respond!' do
    it 'triggers a respond event' do
      expect do
        case_with_response.state_machine.respond! responder,
                                                  responding_team
      end.to trigger_the_event(:respond)
               .on_state_machine(case_with_response.state_machine)
               .with_parameters(user_id: responder.id,
                                responding_team_id: responding_team.id)
    end
  end


  describe 'trigger add_message_to_case!' do

    it 'triggers the event' do
      expect{
        responded_case.state_machine.add_message_to_case!(responded_case.responder, 'This is the message')
      }.to trigger_the_event(:add_message_to_case)
            .on_state_machine(responded_case.state_machine)
            .with_parameters(user_id: responded_case.responder.id, message: 'This is the message')
    end

    it 'creates a message transition record' do
      expect {
        case_being_drafted.state_machine.add_message_to_case!(
          case_being_drafted.responder, 'This is my message to you all')
      }.to change{case_being_drafted.transitions.size}.by(1)
    end

    it 'transition record is set up correctly' do
      case_being_drafted.state_machine.add_message_to_case!(
        case_being_drafted.responder, 'This is my message to you all')
      transition = case_being_drafted.transitions.last
      expect(transition.event).to eq 'add_message_to_case'
      expect(transition.user_id).to eq case_being_drafted.responder.id
      expect(transition.message).to eq 'This is my message to you all'
    end
  end


  context 'approvals' do

    let(:kase) { pending_dacu_clearance_case }
    let(:approver) { pending_dacu_clearance_case.approvers.first }
    let(:state_machine) { kase.state_machine }
    let(:team_id) { kase.approving_teams.first.id }
    let(:filenames) { %w(file1.pdf file2.pdf) }

    describe 'trigger approve!' do
      it 'triggers an approve event' do
        expect {
          state_machine.approve!(approver, kase.approver_assignments.first)
        }.to trigger_the_event(:approve).on_state_machine(state_machine).with_parameters(
          user_id: approver.id,
          approving_team_id: team_id
        )
      end
    end

    describe 'trigger upload_response_and_approve!' do
      it 'triggers an upload_response_and_approve_event' do
        expect {
          state_machine.upload_response_and_approve!(approver,
                                                     kase.approving_teams.first,
                                                     filenames)
        }.to trigger_the_event(:upload_response_and_approve).on_state_machine(state_machine).with_parameters(
          user_id: approver.id,
          approving_team_id: team_id,
          filenames: filenames
        )
      end
    end

    describe 'trigger upload_response_and_return_for_redraft!' do
      it 'triggers an upload_response_and_return_for_redraft event' do
        expect {
          state_machine.upload_response_and_return_for_redraft!(approver,
                                                     kase.approving_teams.first,
                                                     filenames)
        }.to trigger_the_event(:upload_response_and_return_for_redraft).on_state_machine(state_machine).with_parameters(
          user_id: approver.id,
          approving_team_id: team_id,
          filenames: filenames
        )
      end
    end
  end

  describe 'trigger close!' do
    it 'triggers a close event' do
      expect do
        responded_case.state_machine.close! manager,
                                            managing_team
      end.to trigger_the_event(:close)
               .on_state_machine(responded_case.state_machine)
               .with_parameters(user_id: manager.id,
                                managing_team_id: managing_team.id)
    end
  end

  describe '.event_name' do
    context 'valid state machine event' do
      it 'returns human readable format' do
        expect(CaseStateMachine.event_name(:accept_responder_assignment)).to eq 'Accept responder assignment'
      end
    end

    context 'invalid state machine event' do
      it 'returns nil' do
        expect(CaseStateMachine.event_name(:trigger_article_50)).to be_nil
      end
    end
  end
end
