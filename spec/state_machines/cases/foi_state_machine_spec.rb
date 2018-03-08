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
  Case::FOIStateMachine.events[event_name]
end


RSpec.describe Case::FOI::StandardStateMachine, type: :model do
  let(:kase)               {
    create :case
  }
  let(:state_machine) do
    described_class.new(
      kase,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end
  let(:managing_team)      { find_or_create :team_dacu }
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
  let(:assigned_flagged_case) { create :pending_dacu_clearance_case, :flagged_accepted,
                                       responding_team: responding_team,
                                       approver: approver }
  let(:case_being_drafted) { create :case_being_drafted,
                                    responder: responder,
                                    responding_team: responding_team}
  let(:case_with_response) { create :case_with_response,
                                    :flagged,
                                    responder: responder,
                                    responding_team: responding_team }
  let(:responded_case)     { create :responded_case,
                                    :flagged,
                                     responder: responder,
                                     responding_team: responding_team }
  let(:closed_case)        { create :closed_case,
                             responder: responder,
                             responding_team: responding_team }

  let(:approved_case)   { create :approved_case }
  let(:pending_dacu_clearance_case)    { create :pending_dacu_clearance_case }
  let(:pending_private_clearance_case) { create :pending_private_clearance_case }
  let(:disclosure_specialist)          { create :disclosure_specialist }
  let(:team_dacu_disclosure)           { find_or_create :team_dacu_disclosure }

  let!(:service) do
    double(NotifyResponderService, call: true).tap do |svc|
      allow(NotifyResponderService).to receive(:new).and_return(svc)
    end
  end

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
    it { should transition_from(:unassigned)
                  .to(:awaiting_responder)
                  .checking_policy(:can_assign_case?)
    }
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
    it { should transition_from(:unassigned).to(:unassigned)
                  .checking_default_policy(Case::BasePolicy)  }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder).checking_default_policy(Case::BasePolicy)  }
    it { should transition_from(:drafting).to(:drafting).checking_default_policy(Case::BasePolicy)  }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch).checking_default_policy(Case::BasePolicy)  }
  end

  events :accept_approver_assignment do
    it { should transition_from(:unassigned).to(:unassigned)
                  .checking_policy(:can_accept_or_reject_approver_assignment?) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder)
                  .checking_policy(:can_accept_or_reject_approver_assignment?) }
    it { should transition_from(:drafting).to(:drafting)
                  .checking_policy(:can_accept_or_reject_approver_assignment?) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch)
                  .checking_policy(:can_accept_or_reject_approver_assignment?) }
    it { should transition_from(:responded).to(:responded)
                  .checking_policy(:can_accept_or_reject_approver_assignment?) }
  end

  events :unaccept_approver_assignment do
    it { should transition_from(:unassigned).to(:unassigned)
                  .checking_policy(:can_unaccept_approval_assignment?) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder)
                  .checking_policy(:can_unaccept_approval_assignment?) }
    it { should transition_from(:drafting).to(:drafting)
                  .checking_policy(:can_unaccept_approval_assignment?) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch)
                  .checking_policy(:can_unaccept_approval_assignment?) }
    it { should transition_from(:pending_dacu_clearance).to(:pending_dacu_clearance)
                  .checking_policy(:can_unaccept_approval_assignment?) }
  end

  events :reassign_user do
    it { should transition_from(:unassigned)
                  .to(:unassigned)
                  .checking_policy(:reassign_user?)  }
    it { should transition_from(:awaiting_responder)
                  .to(:awaiting_responder)
                  .checking_policy(:reassign_user?)  }

    it { should transition_from(:drafting)
                    .to(:drafting)
                    .checking_policy(:reassign_user?)  }
    it { should transition_from(:pending_dacu_clearance)
                    .to(:pending_dacu_clearance)
                    .checking_policy(:reassign_user?) }
    it { should transition_from(:pending_press_office_clearance)
                    .to(:pending_press_office_clearance)
                    .checking_policy(:reassign_user?) }

  end

  events :accept_responder_assignment do
    it { should transition_from(:awaiting_responder).to(:drafting)
                  .checking_policy(:can_accept_or_reject_responder_assignment?) }
  end

  events :reject_responder_assignment do
    it { should transition_from(:awaiting_responder).to(:unassigned)
                  .checking_policy(:can_accept_or_reject_responder_assignment?) }
  end

  events :add_responses do
    it { should transition_from(:drafting).to(:awaiting_dispatch)
                  .checking_policy(:can_add_attachment?) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch)
                  .checking_policy(:can_add_attachment?) }
  end

  events :add_response_to_flagged_case do
    it { should transition_from(:drafting)
                  .to(:pending_dacu_clearance)
                  .checking_default_policy(Case::BasePolicy) }
  end

  events :remove_response do
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch)
                  .checking_policy(:can_remove_attachment?) }
  end

  events :remove_last_response do
    it { should transition_from(:awaiting_dispatch).to(:drafting)
                  .checking_policy(:can_remove_attachment?) }
  end

  events :respond do
    it { should transition_from(:awaiting_dispatch).to(:responded)
                  .checking_policy(:can_respond?) }
  end

  events :approve do
    it { should transition_from(:pending_dacu_clearance)
                   .to(:awaiting_dispatch)
                   .checking_default_policy(Case::BasePolicy) }
    it { should transition_from(:pending_dacu_clearance)
                  .to(:pending_press_office_clearance)
                  .checking_default_policy(Case::BasePolicy) }
    it { should transition_from(:pending_press_office_clearance)
                  .to(:awaiting_dispatch)
                  .checking_default_policy(Case::BasePolicy) }
    it { should transition_from(:pending_press_office_clearance)
                  .to(:pending_private_office_clearance)
                  .checking_default_policy(Case::BasePolicy) }
    it { should transition_from(:pending_private_office_clearance)
                  .to(:awaiting_dispatch)
                  .checking_default_policy(Case::BasePolicy) }
  end

  events :request_amends do
    it { should transition_from(:pending_press_office_clearance)
                  .to(:pending_dacu_clearance)
                  .checking_default_policy(Case::BasePolicy) }
    it { should transition_from(:pending_private_office_clearance)
                  .to(:pending_dacu_clearance)
                  .checking_default_policy(Case::BasePolicy) }
  end

  events :upload_response_and_approve do
    it { should transition_from(:pending_dacu_clearance)
                    .to(:awaiting_dispatch)
                    .checking_default_policy(Case::BasePolicy)}
    it { should transition_from(:pending_dacu_clearance)
                  .to(:pending_press_office_clearance)
                  .checking_default_policy(Case::BasePolicy)}
  end

  events :upload_response_and_return_for_redraft do
    it { should transition_from(:pending_dacu_clearance)
                  .to(:drafting)
                  .checking_default_policy(Case::BasePolicy) }
  end

  events :close do
    it { should transition_from(:responded).to(:closed)
                  .checking_policy(:can_close_case?) }
  end

  events :add_message_to_case do
    it { should transition_from(:unassigned).to(:unassigned)
                  .checking_policy(:can_add_message_to_case?) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder)
                  .checking_policy(:can_add_message_to_case?) }
    it { should transition_from(:drafting).to(:drafting)
                  .checking_policy(:can_add_message_to_case?) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch)
                  .checking_policy(:can_add_message_to_case?) }
    it { should transition_from(:pending_dacu_clearance)
                  .to(:pending_dacu_clearance)
                  .checking_policy(:can_add_message_to_case?) }
    it { should transition_from(:pending_press_office_clearance)
                  .to(:pending_press_office_clearance)
                  .checking_policy(:can_add_message_to_case?) }
    it { should transition_from(:pending_private_office_clearance)
                  .to(:pending_private_office_clearance)
                  .checking_policy(:can_add_message_to_case?) }
    it { should transition_from(:responded).to(:responded)
                  .checking_policy(:can_add_message_to_case?) }
  end

  events :edit_case do
    it { should transition_from(:unassigned).to(:unassigned)
                  .checking_policy(:edit_case?) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder)
                  .checking_policy(:edit_case?) }
    it { should transition_from(:drafting).to(:drafting)
                  .checking_policy(:edit_case?) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch)
                  .checking_policy(:edit_case?) }
    it { should transition_from(:pending_dacu_clearance)
                  .to(:pending_dacu_clearance)
                  .checking_policy(:edit_case?) }
    it { should transition_from(:pending_press_office_clearance)
                  .to(:pending_press_office_clearance)
                  .checking_policy(:edit_case?) }
    it { should transition_from(:pending_private_office_clearance)
                  .to(:pending_private_office_clearance)
                  .checking_policy(:edit_case?) }
    it { should transition_from(:responded).to(:responded)
                  .checking_policy(:edit_case?) }
  end

  events :destroy_case do
    it { should transition_from(:unassigned).to(:unassigned)
                  .checking_policy(:destroy_case?) }
    it { should transition_from(:awaiting_responder).to(:awaiting_responder)
                  .checking_policy(:destroy_case?) }
    it { should transition_from(:drafting).to(:drafting)
                  .checking_policy(:destroy_case?) }
    it { should transition_from(:awaiting_dispatch).to(:awaiting_dispatch)
                  .checking_policy(:destroy_case?) }
    it { should transition_from(:pending_dacu_clearance)
                  .to(:pending_dacu_clearance)
                  .checking_policy(:destroy_case?) }
    it { should transition_from(:pending_press_office_clearance)
                  .to(:pending_press_office_clearance)
                  .checking_policy(:destroy_case?) }
    it { should transition_from(:pending_private_office_clearance)
                  .to(:pending_private_office_clearance)
                  .checking_policy(:destroy_case?) }
    it { should transition_from(:responded).to(:responded)
                  .checking_policy(:destroy_case?) }
  end

  events :extend_for_pit do
    it { should transition_from(:awaiting_dispatch)
                  .to(:awaiting_dispatch) }
    it { should transition_from(:drafting)
                  .to(:drafting) }
    it { should transition_from(:pending_dacu_clearance)
                  .to(:pending_dacu_clearance) }
    it { should transition_from(:pending_press_office_clearance)
                  .to(:pending_press_office_clearance) }
    it { should transition_from(:pending_private_office_clearance)
                  .to(:pending_private_office_clearance) }
    it { should transition_from(:responded)
                  .to(:responded) }
  end

  events :request_further_clearance do
    it { should transition_from(:unassigned)
                  .to(:unassigned)
                  .checking_policy(:can_request_further_clearance?) }
    it { should transition_from(:awaiting_responder)
                  .to(:awaiting_responder)
                  .checking_policy(:can_request_further_clearance?) }
    it { should transition_from(:drafting)
                  .to(:drafting)
                  .checking_policy(:can_request_further_clearance?) }
    it { should transition_from(:pending_dacu_clearance)
                  .to(:pending_dacu_clearance)
                  .checking_policy(:can_request_further_clearance?) }
    it { should transition_from(:awaiting_dispatch)
                  .to(:awaiting_dispatch)
                  .checking_policy(:can_request_further_clearance?) }
  end


  describe 'switching workflows' do
    context 'unflag  for clearance' do
      it 'should switch the workflow on the case' do
       # given
       kase = flagged_accepted_case
       expect(kase.current_state).to eq 'drafting'
       expect(kase.workflow).to eq 'trigger'
       expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)

       # when
       kase.state_machine.unflag_for_clearance!(acting_user: approver, acting_team: managing_team, target_team: approving_team, message: 'I do not need to approve this')

       # then
       expect(kase.current_state).to eq 'drafting'
       expect(kase.workflow).to eq 'standard'
       expect(kase.reload.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)
      end

      it 'should record the workflow in the transition' do
        # given
        kase = flagged_accepted_case
        expect(kase.current_state).to eq 'drafting'
        expect(kase.workflow).to eq 'trigger'
        expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)

        # when
        kase.state_machine.unflag_for_clearance!(acting_user: approver, acting_team: managing_team, target_team: approving_team, message: 'I do not need to approve this')

        # then
        transition = kase.reload.transitions.last
        expect(transition.event).to eq 'unflag_for_clearance'
        expect(transition.to_state).to eq 'drafting'
        expect(transition.to_workflow).to eq 'standard'
      end
    end
  end

  describe 'trigger assign_responder!' do
    # it 'triggers an assign_responder event' do
    #   expect do
    #     new_case.state_machine.assign_responder! manager,
    #                                              managing_team,
    #                                              responding_team
    #   end.to trigger_the_event(:assign_responder)
    #            .on_state_machine(new_case.state_machine)
    #            .with_parameters acting_user_id:   manager.id,
    #                             acting_team_id:   managing_team.id,
    #                             target_team_id:   responding_team.id
    # end
  end

  describe 'trigger flag_for_clearance!' do
    it 'triggers a flag_for_clearance event' do
      expect do
        assigned_flagged_case.state_machine.flag_for_clearance! acting_user: manager,
                                                        acting_team: managing_team,
                                                        target_team: approving_team
      end
        .to trigger_the_event(:flag_for_clearance)
              .on_state_machine(assigned_flagged_case.state_machine)
              .with_parameters acting_user_id: manager.id,
                               acting_team_id: managing_team.id,
                               target_team_id: approving_team.id
    end
  end

  describe 'trigger unflag_for_clearance!' do
    it 'triggers an unflag_for_clearance event' do
      expect do
        assigned_flagged_case.state_machine.unflag_for_clearance!(acting_user: manager,
                                                                  acting_team: managing_team,
                                                                  target_team: approving_team,
                                                                  message: "message")
      end
        .to trigger_the_event(:unflag_for_clearance)
              .on_state_machine(assigned_flagged_case.state_machine)
              .with_parameters acting_user_id: manager.id,
                               acting_team_id: managing_team.id,
                               target_team_id: approving_team.id,
                               message: "message"
    end
  end

  describe 'trigger accept_approver_assignment!' do
    it 'triggers an accept_approver_assignment event' do
      expect do
        assigned_flagged_case.state_machine.accept_approver_assignment! acting_user: approver,
                                                                acting_team: approving_team
      end.to trigger_the_event(:accept_approver_assignment)
               .on_state_machine(assigned_flagged_case.state_machine)
               .with_parameters(acting_user_id: approver.id,
                                acting_team_id: approving_team.id)
    end
  end

  describe 'trigger unaccept_approver_assignment!' do
    it 'triggers unaccept_approver_assignment event' do
      expect {
        assigned_flagged_case.state_machine.unaccept_approver_assignment!(
                            acting_user: approver,
                            acting_team: approving_team)
      }.to trigger_the_event(:unaccept_approver_assignment)
              .on_state_machine(assigned_flagged_case.state_machine)
              .with_parameters(acting_user_id: approver.id, acting_team_id: approving_team.id)
    end
  end

  describe 'trigger accept_responder_assignment!' do
    it 'triggers an accept_responder_assignment event' do
      expect do
        assigned_flagged_case.state_machine.accept_responder_assignment!(
                            acting_user: responder,
                            acting_team: responding_team)
      end.to trigger_the_event(:accept_responder_assignment)
               .on_state_machine(assigned_flagged_case.state_machine)
               .with_parameters(acting_user_id: responder.id,
                                acting_team_id: responding_team.id)
    end
  end


  describe 'trigger a reassign_user' do

    describe 'flagged case' do
      let(:kase) { flagged_accepted_case }
      it 'triggers a reassign_user'do
        expect(kase.state_machine).
            to receive(:trigger_event).
                with(event: :reassign_user, params: { target_user: other_approver,
                                                      target_team: approving_team,
                                                      acting_user: approver,
                                                      acting_team: approving_team })

        kase.state_machine.reassign_user!(
            target_user: other_approver,
            target_team: approving_team,
            acting_user: approver,
            acting_team: approving_team )
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
        assigned_flagged_case.state_machine.reject_responder_assignment! acting_user: responder,
                                                                 acting_team: responding_team,
                                                                 message: message
      end.to trigger_the_event(:reject_responder_assignment)
               .on_state_machine(assigned_flagged_case.state_machine)
               .with_parameters(acting_user_id: responder.id,
                                acting_team_id: responding_team.id,
                                message: message,
                                event: :reject_responder_assignment)
    end
  end

  describe 'trigger add_responses!' do
    let(:filenames) { ['file1.pdf', 'file2.pdf'] }

    it 'triggers an add_responses event' do
      expect(case_being_drafted.state_machine).
          to receive(:trigger_event).
              with(event: :add_responses,
                   params: {  acting_user: responder,
                              acting_team: responding_team,
                              filenames: filenames,
                              message: ' ' })
      case_being_drafted.state_machine.add_responses! acting_user: responder,
                                                      acting_team: case_being_drafted.responding_team,
                                                      filenames: filenames,
                                                      message: ' '
    end
  end

  describe 'trigger remove_response!' do
    let(:filenames) { ['file1.pdf'] }

    context 'no attachments left' do
      it 'triggers a remove_last_response event' do
        expect do
          case_with_response.state_machine.remove_response! acting_user: responder,
                                                            acting_team: responding_team,
                                                            filenames: filenames,
                                                            num_attachments: 0
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
          acting_user: responder,
          acting_team: responding_team,
          filenames: filenames,
          num_attachments: 1,
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
        case_with_response.state_machine.respond!(
            acting_user: responder,
            acting_team: case_with_response.responding_team)
      end.to trigger_the_event(:respond)
               .on_state_machine(case_with_response.state_machine)
               .with_parameters(acting_user_id: responder.id,
                                acting_team_id: responding_team.id)
    end
  end

  describe 'trigger add_message_to_case!' do

    let(:user)      { responded_case.responder }
    let(:team)      { responded_case.responding_team }

    it 'triggers the event' do
      expect{
        responded_case.state_machine.add_message_to_case!(acting_user: user, acting_team: team, message: 'This is the message')
      }.to trigger_the_event(:add_message_to_case)
            .on_state_machine(responded_case.state_machine)
            .with_parameters(acting_user_id: responded_case.responder.id, acting_team_id: team.id, message: 'This is the message')
    end

    it 'creates a message transition record' do
      expect {
        case_being_drafted.state_machine.add_message_to_case!(
          acting_user: user, acting_team: team, message: 'This is my message to you all')
      }.to change{case_being_drafted.transitions.size}.by(1)
    end

    it 'transition record is set up correctly' do
      case_being_drafted.state_machine.add_message_to_case!(
        acting_user: user, acting_team: team, message: 'This is my message to you all')
      transition = case_being_drafted.transitions.last
      expect(transition.event).to eq 'add_message_to_case'
      expect(transition.acting_user_id).to eq case_being_drafted.responder.id
      expect(transition.message).to eq 'This is my message to you all'
    end

    context 'user sending message is the resonder' do
      it 'does not call the notify responder service' do
        case_being_drafted.state_machine.add_message_to_case!(
          acting_user: user,
          acting_team: team,
          message: 'This is my message to you all')
        expect(NotifyResponderService)
          .not_to have_received(:new).with(case_being_drafted, 'Message received')
      end
    end

    context 'user sending message is not the responder' do
      let(:user)      { find_or_create :manager }
      let(:team)      { responded_case.managing_team }
      it 'calls the notify responder service' do
        case_being_drafted.state_machine.add_message_to_case!(
          acting_user: user, acting_team: team, message: 'This is my message to you all')
        expect(NotifyResponderService)
          .to have_received(:new).with(case_being_drafted, 'Message received')
        expect(service).to have_received(:call)
      end
    end

    context 'case has not been accepted' do
      let(:kase)      { create :awaiting_responder_case }
      let(:user)      { find_or_create :manager }
      let(:team)      { responded_case.managing_team }
      it ' does not call the notify responder service' do
        kase.state_machine.add_message_to_case!(
          acting_user: user,
          acting_team: team,
          message: 'This is my message to you all')
        expect(NotifyResponderService)
          .not_to have_received(:new).with(kase, 'Message received')
      end
    end
  end

  describe 'trigger extend_for_pit!' do
    it 'triggers a extend_for_pit event' do
      new_deadline = 30.business_days.from_now
      expect do
        case_with_response.state_machine.extend_for_pit! acting_user: manager,
                                                         acting_team: manager.teams.first,
                                                         final_deadline: new_deadline,
                                                         message: 'for test'
      end.to trigger_the_event(:extend_for_pit)
               .on_state_machine(case_with_response.state_machine)
               .with_parameters(acting_user_id: manager.id,
                                acting_team_id: managing_team.id,
                                final_deadline: new_deadline,
                                message: 'for test')
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
          state_machine.approve!(acting_user: approver, acting_team: kase.approver_assignments.first.team)
        }.to trigger_the_event(:approve).on_state_machine(state_machine).with_parameters(
          acting_user_id: approver.id,
          acting_team_id: team_id
        )
      end
      it 'calls the notify responder service' do
        state_machine.approve!(acting_user: approver, acting_team: kase.approver_assignments.first.team)
        expect(NotifyResponderService)
          .to have_received(:new).with(kase, 'Ready to send')
        expect(service).to have_received(:call)
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
      it 'calls the notify responder service' do
        state_machine.upload_response_and_approve!(approver,
                                                   kase.approving_teams.first,
                                                   filenames)
        expect(NotifyResponderService)
          .to have_received(:new).with(kase, 'Ready to send')
        expect(service).to have_received(:call)
      end
    end

    describe 'trigger upload_response_and_return_for_redraft!' do
      it 'triggers an upload_response_and_return_for_redraft event' do
        expect {
          state_machine.upload_response_and_return_for_redraft!(acting_user: approver,
                                                     acting_team: kase.approving_teams.first,
                                                     filenames: filenames)
        }.to trigger_the_event(:upload_response_and_return_for_redraft).on_state_machine(state_machine).with_parameters(
          acting_user_id: approver.id,
          acting_team_id: team_id,
          filenames: filenames,
          message: 'Uploading....'
        )
      end

      it 'calls the notify responder service' do
        state_machine.upload_response_and_return_for_redraft!(acting_user: approver,
                                                   acting_team: kase.approving_teams.first,
                                                   filenames: filenames)
        expect(NotifyResponderService)
          .to have_received(:new).with(kase, 'Redraft requested')
        expect(service).to have_received(:call)
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
            acting_user: approver,
            acting_team: kase.approving_teams.first
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
        responded_case.state_machine.close! acting_user: manager, acting_team: responded_case.managing_team
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
        expect(described_class.event_name(:close)).to eq 'Case closed'
      end
    end

    context 'event has no i18n entry' do
      it 'returns human readable format' do
        allow(described_class).to receive(:events)
                                     .and_return({fake_event: nil})
        expect(described_class.event_name(:fake_event))
          .to eq 'Fake event'
      end
    end

    context 'invalid state machine event' do
      it 'returns nil' do
        expect(described_class.event_name(:trigger_article_50)).to be_nil
      end
    end
  end

  context 'User edits a case' do
    let(:kase) { create :case_with_response, :flagged }
    let(:manager) { create :manager }
    let(:state_machine) { kase.state_machine }
    let(:team) { manager.managing_teams.first }

    describe 'trigger edit_case!' do
      it 'triggers an edit_case event' do
        expect {
          state_machine.edit_case!(
            acting_user: manager,
            acting_team: team
          )
        }.to trigger_the_event(:edit_case)
               .on_state_machine(state_machine)
               .with_parameters(
                 acting_user_id: manager.id,
                 acting_team_id: team.id
               )
      end

    end
  end

  context 'User deletes a case' do
    let(:kase) { create :case_with_response, :flagged }
    let(:manager) { create :manager }
    let(:state_machine) { kase.state_machine }
    let(:team) { manager.managing_teams.first }

    describe 'trigger destroy_case!' do
      it 'triggers an destroy_case event' do
        expect {
          state_machine.destroy_case!(
            acting_user: manager,
            acting_team: team
          )
        }.to trigger_the_event(:destroy_case)
               .on_state_machine(state_machine)
               .with_parameters(
                 acting_user_id: manager.id,
                 acting_team_id: team.id
               )
      end
    end
  end

  describe '#notify_kilo_case_is_ready_to_send' do
    let(:approved_case)   { create :approved_case, :flagged }
    let(:kase)            { create :case }
    let!(:service) do
      double(NotifyResponderService, call: true).tap do |svc|
        allow(NotifyResponderService).to receive(:new).and_return(svc)
      end
    end

    # context 'case state is awaiting_dispatch' do
    #   it 'calls the service' do
    #     approved_case.state_machine.notify_kilo_case_is_ready_to_send(approved_case)
    #     expect(NotifyResponderService)
    #       .to have_received(:new).with(approved_case)
    #     expect(service).to have_received(:call)
    #   end
    # end

    context 'case state is not awaiting_dispatch' do
      # it 'does not calls the service' do
      #   new_case.state_machine.notify_kilo_case_is_ready_to_send(new_case)
      #   expect(NotifyResponderService)
      #     .not_to have_received(:new).with(new_case)
      #   expect(service).not_to have_received(:call)
      # end
    end
  end

  describe '#request_further_clearance' do
    let(:accepted_case) { create :accepted_case }
    let(:manager) { create :manager }
    let(:state_machine) { accepted_case.state_machine }
    let(:team) { manager.managing_teams.first }

    it 'triggers an request_further_clearance event' do
      expect(kase.state_machine).to receive(:trigger_event).with(event: :request_further_clearance,
                                                                params:{
                                                                  acting_user: manager,
                                                                  acting_team: team,
                                                                  target_user: accepted_case.responder,
                                                                  target_team: accepted_case.responding_team})
      kase.state_machine.request_further_clearance!(
        acting_user: manager,
        acting_team: team,
        target_user: accepted_case.responder,
        target_team: accepted_case.responding_team )

    end
  end
end
