require 'rails_helper'

# helper class to make example groups a bit more readable below
def events(*list, &block)
  describe(*list, events: list, caller: caller) do
    instance_eval(&block)
  end
end


def fevents(*list, &block)
  fdescribe(*list, events: list, caller: caller) do
    instance_eval(&block)
  end
end


def xevents(*list, &block)
  xdescribe(*list, events: list, caller: caller) do
    instance_eval(&block)
  end
end


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
  let(:another_responder)  { responding_team.responders.first }
  let(:approving_team)     { create :approving_team }
  let(:approver)           { approving_team.approvers.first }
  let(:other_approver)     {
    create :approver, approving_team: approving_team
  }

  let(:flagged_accepted_case){
    create :accepted_case, :flagged_accepted, approver: approver
  }

  let(:new_case)           { create :case }
  let(:assigned_case)      { create :assigned_case,
                                 responding_team: responding_team }
  let(:assigned_flagged_case) { create :assigned_case, :flagged_accepted,
                                       responding_team: responding_team,
                                       approver: approver }
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

  let(:pending_dacu_clearance_case)    { create :pending_dacu_clearance_case }
  let(:pending_private_clearance_case) { create :pending_private_clearance_case }
  let(:disclosure_specialist)          { create :disclosure_specialist }
  let(:team_dacu_disclosure)           { find_or_create :team_dacu_disclosure }

  context 'after transition' do
    let(:t1) { Time.now }
    let(:t2) { Time.now + 3.days }

    it 'stores current state and time of transition on the case record' do
      Timecop.freeze(t1) do
        expect(kase.current_state).to eq 'unassigned'
        expect(kase.last_transitioned_at).to eq t1
      end
      Timecop.freeze(t2) do
        state_machine.trigger! :assign_responder,
                               acting_team_id:     managing_team.id,
                               target_team_id:     responding_team.id,
                               acting_user_id:     manager.id,
                               event:              :assign_responder
      end
      expect(kase.current_state).to eq 'awaiting_responder'
      expect(kase.last_transitioned_at).to eq t2
    end
  end

  events :assign_responder do
    it { should transition_from(:unassigned).to(:awaiting_responder) }
    it { should require_permission(:can_assign_case?)
                  .using_options(acting_user_id: manager.id)
                  .using_object(new_case) }
  end

  events :flag_for_clearance do
    it { should transition_from(:unassigned).to(:unassigned) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should require_permission(:can_flag_for_clearance?)
                  .using_options(acting_user_id: manager.id)
                  .using_object(assigned_case) }
  end

  events :unflag_for_clearance do
    it { should transition_from(:unassigned).to(:unassigned).checking_default_policy(CasePolicy)  }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder).checking_default_policy(CasePolicy)  }
    it { should transition_from(:drafting).to(:drafting).checking_default_policy(CasePolicy)  }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch).checking_default_policy(CasePolicy)  }
  end

  events :accept_approver_assignment do
    it { should transition_from(:unassigned).to(:unassigned) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should transition_from(:responded).to(:responded) }
    it { should require_permission(:can_accept_or_reject_approver_assignment?)
                  .using_options(acting_user_id: approver.id)
                  .using_object(kase) }
  end

  events :unaccept_approver_assignment do
    it { should transition_from(:unassigned).to(:unassigned) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should transition_from(:pending_dacu_clearance).to(:pending_dacu_clearance) }
    it { should require_permission(:can_unaccept_approval_assignment?)
            .using_options(acting_user_id: approver.id)
            .using_object(kase) }
  end

  events :reassign_user do
    it { should transition_from(:drafting)
                    .to(:drafting)
                    .checking_policy(:reassign_user?, CasePolicy)  }
    it { should transition_from(:pending_dacu_clearance)
                    .to(:pending_dacu_clearance)
                    .checking_policy(:reassign_user?, CasePolicy) }
    it { should transition_from(:pending_press_office_clearance)
                    .to(:pending_press_office_clearance)
                    .checking_policy(:reassign_user?, CasePolicy) }

  end

  events :accept_responder_assignment do
    it { should transition_from(:awaiting_responder).to(:drafting) }
    it { should require_permission(:can_accept_or_reject_responder_assignment?)
                  .using_options(acting_user_id: responder.id)
                  .using_object(assigned_case) }
  end

  events :reject_responder_assignment do
    it { should transition_from(:awaiting_responder).to(:unassigned) }
    it { should require_permission(:can_accept_or_reject_responder_assignment?)
                  .using_options(acting_user_id: responder.id)
                  .using_object(assigned_case) }
  end

  events :add_responses do
    it { should transition_from(:drafting).to(:awaiting_dispatch) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should require_permission(:can_add_attachment?)
                  .using_options(acting_user_id: responder.id)
                  .using_object(case_being_drafted) }
  end

  events :add_response_to_flagged_case do
    it { should transition_from(:drafting)
                  .to(:pending_dacu_clearance)
                  .checking_default_policy(CasePolicy) }
  end

  events :remove_response do
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should require_permission(:can_remove_attachment?)
                  .using_options(acting_user_id: responder.id)
                  .using_object(case_with_response) }
  end

  events :remove_last_response do
    it { should transition_from(:awaiting_dispatch).to(:drafting) }
    it { should require_permission(:can_remove_attachment?)
                  .using_options(acting_user_id: responder.id)
                  .using_object(case_with_response) }
  end

  events :respond do
    it { should transition_from(:awaiting_dispatch).to(:responded) }
    it { should require_permission(:can_respond?)
                  .using_options(acting_user_id: responder.id)
                  .using_object(case_with_response) }
  end

  events :approve do
    it { should transition_from(:pending_dacu_clearance)
                   .to(:awaiting_dispatch)
                   .checking_default_policy(CasePolicy) }
    it { should transition_from(:pending_dacu_clearance)
                  .to(:pending_press_office_clearance)
                  .checking_default_policy(CasePolicy) }
    it { should transition_from(:pending_press_office_clearance)
                  .to(:awaiting_dispatch)
                  .checking_default_policy(CasePolicy) }
    it { should transition_from(:pending_press_office_clearance)
                  .to(:pending_private_office_clearance)
                  .checking_default_policy(CasePolicy) }
    it { should transition_from(:pending_private_office_clearance)
                  .to(:awaiting_dispatch)
                  .checking_default_policy(CasePolicy) }
  end

  events :request_amends do
    it { should transition_from(:pending_press_office_clearance)
                  .to(:pending_dacu_clearance)
                  .checking_default_policy(CasePolicy) }
    it { should transition_from(:pending_private_office_clearance)
                  .to(:pending_dacu_clearance)
                  .checking_default_policy(CasePolicy) }
  end

  events :upload_response_and_approve do
    it { should transition_from(:pending_dacu_clearance)
                    .to(:awaiting_dispatch)
                    .checking_default_policy(CasePolicy)}
  end

  events :upload_response_and_return_for_redraft do
    it { should transition_from(:pending_dacu_clearance)
                  .to(:drafting)
                  .checking_default_policy(CasePolicy) }
  end

  events :close do
    it { should transition_from(:responded).to(:closed) }
    it { should require_permission(:can_close_case?)
                  .using_options(acting_user_id: manager.id)
                  .using_object(responded_case) }
  end

  events :add_message_to_case do
    it { should transition_from(:unassigned).to(:unassigned) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder) }
    it { should transition_from(:drafting).to(:drafting) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch) }
    it { should transition_from(:pending_dacu_clearance).to(:pending_dacu_clearance) }
    it { should transition_from(:responded).to(:responded) }
    it { should require_permission(:can_add_message_to_case?)
                  .using_options(acting_user_id: manager.id)
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
               .with_parameters acting_user_id:   manager.id,
                                acting_team_id:   managing_team.id,
                                target_team_id:   responding_team.id
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
              .with_parameters acting_user_id: manager.id,
                               acting_team_id: managing_team.id,
                               target_team_id: approving_team.id
    end
  end

  describe 'trigger unflag_for_clearance!' do
    it 'triggers an unflag_for_clearance event' do
      expect do
        assigned_case.state_machine.unflag_for_clearance! manager,
                                                          managing_team,
                                                          approving_team
      end
        .to trigger_the_event(:unflag_for_clearance)
              .on_state_machine(assigned_case.state_machine)
              .with_parameters acting_user_id: manager.id,
                               acting_team_id: managing_team.id,
                               target_team_id: approving_team.id
    end
  end

  describe 'trigger accept_approver_assignment!' do
    it 'triggers an accept_approver_assignment event' do
      expect do
        assigned_case.state_machine.accept_approver_assignment! approver,
                                                                approving_team
      end.to trigger_the_event(:accept_approver_assignment)
               .on_state_machine(assigned_case.state_machine)
               .with_parameters(acting_user_id: approver.id,
                                acting_team_id: approving_team.id)
    end
  end

  describe 'trigger unaccept_approver_assignment!' do
    it 'triggers unaccept_approver_assignment event' do
      expect {
        assigned_case.state_machine.unaccept_approver_assignment! approver, approving_team
      }.to trigger_the_event(:unaccept_approver_assignment)
              .on_state_machine(assigned_case.state_machine)
              .with_parameters(acting_user_id: approver.id, acting_team_id: approving_team.id)
    end
  end

  describe 'trigger accept_responder_assignment!' do
    it 'triggers an accept_responder_assignment event' do
      expect do
        assigned_case.state_machine.accept_responder_assignment! responder,
                                                                 responding_team
      end.to trigger_the_event(:accept_responder_assignment)
               .on_state_machine(assigned_case.state_machine)
               .with_parameters(acting_user_id: responder.id,
                                acting_team_id: responding_team.id)
    end
  end

  describe 'trigger a reassign_user' do

    describe 'unflagged cases' do
      let(:kase) { case_being_drafted }

      it 'triggers a reassign_user'do
        expect {
          kase.state_machine.reassign_user!(
              target_user: another_responder,
              target_team: responding_team,
              acting_user: responder,
              acting_team: responding_team )
        }.to trigger_the_event(:reassign_user)
                 .on_state_machine(kase.state_machine)
                 .with_parameters( target_user_id: another_responder.id,
                                   target_team_id: responding_team.id,
                                   acting_user_id: responder.id,
                                   acting_team_id: responding_team.id)
      end

      it 'adds a transition history record' do
        kase.state_machine.reassign_user!(
            target_user: another_responder,
            target_team: responding_team,
            acting_user: responder,
            acting_team: responding_team )

        transition = kase.reload.transitions.last
        expect(transition.event).to eq 'reassign_user'
        expect(transition.to_state).to eq 'drafting'
        expect(transition.target_user_id).to eq another_responder.id
        expect(transition.acting_user_id).to eq responder.id
        expect(transition.target_team_id).to eq responding_team.id
        expect(transition.acting_team_id).to eq responding_team.id
      end
    end

    describe 'flagged cases' do
      let(:kase) { flagged_accepted_case }
      it 'triggers a reassign_user'do
        expect {
          kase.state_machine.reassign_user!(
              target_user: other_approver,
              target_team: approving_team,
              acting_user: approver,
              acting_team: approving_team )
        }.to trigger_the_event(:reassign_user)
                 .on_state_machine(kase.state_machine)
                 .with_parameters( target_user_id: other_approver.id,
                                   target_team_id: approving_team.id,
                                   acting_user_id: approver.id,
                                   acting_team_id: approving_team.id)
      end

      it 'adds a transition history record' do
        kase.state_machine.reassign_user!(
            target_user: other_approver,
            target_team: approving_team,
            acting_user: approver,
            acting_team: approving_team )

        transition = kase.reload.transitions.last
        expect(transition.event).to eq 'reassign_user'
        expect(transition.to_state).to eq 'drafting'
        expect(transition.target_user_id).to eq other_approver.id
        expect(transition.acting_user_id).to eq approver.id
        expect(transition.target_team_id).to eq approving_team.id
        expect(transition.acting_team_id).to eq approving_team.id
      end
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
               .with_parameters(acting_user_id: responder.id,
                                acting_team_id: responding_team.id,
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
               .with_parameters(acting_user_id: responder.id,
                                acting_team_id: responding_team.id,
                                filenames: filenames,
                                message: nil)
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
                 .with_parameters(acting_user_id: responder.id,
                                  acting_team_id: responding_team.id,
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
               .with_parameters(acting_user_id: responder.id,
                                acting_team_id: responding_team.id,
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
               .with_parameters(acting_user_id: responder.id,
                                acting_team_id: responding_team.id)
    end
  end

  describe 'trigger add_message_to_case!' do

    let(:user) { responded_case.responder }
    let(:team)      { responded_case.responding_team }

    it 'triggers the event' do
      expect{
        responded_case.state_machine.add_message_to_case!(user, team, 'This is the message')
      }.to trigger_the_event(:add_message_to_case)
            .on_state_machine(responded_case.state_machine)
            .with_parameters(acting_user_id: responded_case.responder.id, acting_team_id: team.id, message: 'This is the message')
    end

    it 'creates a message transition record' do
      expect {
        case_being_drafted.state_machine.add_message_to_case!(
          user, team, 'This is my message to you all')
      }.to change{case_being_drafted.transitions.size}.by(1)
    end

    it 'transition record is set up correctly' do
      case_being_drafted.state_machine.add_message_to_case!(
        user, team, 'This is my message to you all')
      transition = case_being_drafted.transitions.last
      expect(transition.event).to eq 'add_message_to_case'
      expect(transition.acting_user_id).to eq case_being_drafted.responder.id
      expect(transition.message).to eq 'This is my message to you all'
    end
  end

  context 'dacu disclosure approvals' do
    let(:kase) { pending_dacu_clearance_case }
    let(:approver) { pending_dacu_clearance_case.approvers.first }
    let(:state_machine) { kase.state_machine }
    let(:team_id) { kase.approving_teams.first.id }
    let(:filenames) { %w(file1.pdf file2.pdf) }

    before(:each) { kase.upload_comment = 'Uploading....' }

    describe 'trigger approve!' do
      it 'triggers an approve event' do
        expect {
          state_machine.approve!(approver, kase.approver_assignments.first)
        }.to trigger_the_event(:approve).on_state_machine(state_machine).with_parameters(
          acting_user_id: approver.id,
          acting_team_id: team_id
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
          acting_user_id: approver.id,
          acting_team_id: team_id,
          filenames: filenames,
          message: 'Uploading....'
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
          acting_user_id: approver.id,
          acting_team_id: team_id,
          filenames: filenames,
          message: 'Uploading....'
        )
      end
    end
  end

  context 'case flagged with press and pending dacu approval' do
    let(:kase) { create :pending_dacu_clearance_case, :press_office }
    let(:approver) { pending_dacu_clearance_case.approvers.first }
    let(:state_machine) { kase.state_machine }
    let(:team_id) { kase.approving_teams.first.id }

    describe 'trigger approve!' do
      it 'triggers an approve event' do
        expect {
          state_machine.approve!(
            approver,
            kase.approver_assignments.first
          )
        }.to trigger_the_event(:approve)
               .on_state_machine(state_machine)
               .with_parameters(
                 acting_user_id: approver.id,
                 acting_team_id: team_id
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
               .with_parameters(acting_user_id: manager.id,
                                acting_team_id: managing_team.id)
    end
  end

  describe 'trigger request_amends!' do
    it 'triggers a request_amends event' do
      state_machine = assigned_flagged_case.state_machine
      assignment = assigned_flagged_case.approver_assignments.first
      assigned_flagged_case.request_amends_comment = 'Never use a preposition to end a sentence with'
      expect do
        state_machine.request_amends! approver, assignment
      end.to trigger_the_event(:request_amends)
               .on_state_machine(state_machine)
               .with_parameters(acting_user_id: approver.id,
                                acting_team_id: approving_team.id,
                                message: 'Never use a preposition to end a sentence with')
    end
  end

  describe '.event_name' do
    context 'event has i18n entry' do
      it 'returns translation' do
        expect(CaseStateMachine.event_name(:close)).to eq 'Case closed'
      end
    end

    context 'event has no i18n entry' do
      it 'returns human readable format' do
        allow(CaseStateMachine).to receive(:events)
                                     .and_return({fake_event: nil})
        expect(CaseStateMachine.event_name(:fake_event))
          .to eq 'Fake event'
      end
    end

    context 'invalid state machine event' do
      it 'returns nil' do
        expect(CaseStateMachine.event_name(:trigger_article_50)).to be_nil
      end
    end
  end
end
