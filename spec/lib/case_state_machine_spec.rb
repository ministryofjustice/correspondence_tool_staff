require 'rails_helper'

RSpec.describe CaseStateMachine, type: :model do
  let(:kase) { create :case }
  let(:state_machine) do
    CaseStateMachine.new(
      kase,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end
  let(:managing_team)   { create :managing_team }
  let(:manager)         { managing_team.managers.first }
  let(:responding_team) { create :responding_team }
  let(:responder)       { responding_team.responders.first }
  let(:assignment_id)   { 1 }

  it 'sets the initial state to "unassigned"' do
    expect(kase.current_state).to eq 'unassigned'
  end

  shared_examples 'a case state machine event' do
    let(:event_name!) { "#{event_name}!".to_sym }
    let(:exception) { Class.new Exception }

    it 'uses the unsafe version of event' do
      allow(state_machine).to receive(event_name!)
      state_machine.send(event_name, *args)
      expect(state_machine).to have_received(event_name!).with(*args)
    end

    it 'protects against TransitionFailedError exceptions' do
      allow(state_machine).to receive(event_name!).
                                and_raise(Statesman::TransitionFailedError)
      result = state_machine.send(event_name, *args)
      expect(result).to be_falsey
    end

    it 'protects against TransitionFailedError exceptions' do
      allow(state_machine).to receive(event_name!).
                                and_raise(Statesman::GuardFailedError)
      result = state_machine.send(event_name, *args)
      expect(result).to be_falsey
    end

    it 'allows other exceptions through' do
      allow(state_machine).to receive(event_name!).
                                and_raise(exception)
      expect do
        state_machine.send(event_name, *args)
      end.to raise_exception(exception)
    end
  end

  describe '#assign_responder!' do
    let(:kase) { create :case }

    before do
      state_machine.assign_responder!(manager, managing_team, responding_team)
    end

    it 'triggers an assign_responder event' do
      expect(kase.current_state).to eq 'awaiting_responder'
    end

    describe 'transition' do
      subject { kase.transitions.last }

      it { should have_attributes(
                    event:           'assign_responder',
                    managing_team:   managing_team,
                    responding_team: responding_team,
                    user:            manager,
                  ) }
    end
  end

  describe '#assign_responder' do
    it_behaves_like 'a case state machine event' do
      let(:event_name) { :assign_responder }
      let(:args) { [manager, managing_team, responding_team] }
    end
  end

  describe '#reject_responder_assignment!' do
    let(:message) { |example| "test #{example.description}" }
    let(:kase)    { create :assigned_case }

    before do
      # state_machine.assign_responder!(manager, managing_team responder)
      state_machine.reject_responder_assignment! responder,
                                                 responding_team,
                                                 message
    end

    it 'triggers a reject_responder_assignment event' do
      expect(kase.current_state).to eq 'unassigned'
    end

    it 'triggers the correct event transition' do
      allow(state_machine).to receive(:trigger!)
      state_machine.reject_responder_assignment!(responder.id, message, assignment_id)
      expect(state_machine).to have_received(:trigger!).with(
                                 :reject_responder_assignment,
                                 assignment_id:               assignment_id,
                                 responding_team_id: responding_team.id,
                                 user_id:                     responder.id,
                                 message:                     message,
                                 event:                       :reject_responder_assignment
                               )
    end
  end

  describe '#reject_responder_assignment' do
    before do
      state_machine.assign_responder!(manager, managing_team, responding_team)
    end

    it_behaves_like 'a case state machine event' do
      let(:event_name) { :reject_responder_assignment }
      let(:message) { "#{event_name} test" }
      let(:args) { [responder, message, assignment_id] }
    end
  end

  describe '#accept_responder_assignment!' do
    before do
      state_machine.assign_responder!(manager, responding_team)
      state_machine.accept_responder_assignment!(responder, responding_team)
    end

    it 'triggers a accept_responder_assignment event' do
      expect(kase.current_state).to eq 'drafting'
    end

    it 'triggers the correct event transition' do
      allow(state_machine).to receive(:trigger!)
      state_machine.accept_responder_assignment!(responder, responding_team)
      expect(state_machine).to have_received(:trigger!).with(
                                 :accept_responder_assignment,
                                 responding_team: responding_team,
                                 user:            responder,
                                 event:           :accept_responder_assignment,
                               )
    end
  end

  describe '#accept_responder_assignment' do
    before do
      state_machine.assign_responder!(manager.id, responder.id)
    end

    it_behaves_like 'a case state machine event' do
      let(:event_name) { :accept_responder_assignment }
      let(:args) { [responder.id] }
    end
  end

  describe '#add_responses!' do
    let(:kase)            { create :accepted_case }
    let(:manager)         { kase.managers.first }
    let(:responder)       { kase.responders.first }
    let(:responding_team) { kase.responding_team }

    before do
      state_machine.assign_responder!(manager, responder)
      state_machine.accept_responder_assignment!(responder)
      state_machine.add_responses!(responder, ['file1.pdf', 'file2.pdf'])
    end

    it 'triggers a add_responses event, but does not change current_state' do
      expect(kase.current_state).to eq 'awaiting_dispatch'
    end

    it 'triggers the correct event transition' do
      allow(state_machine).to receive(:trigger!)
      state_machine.add_responses!(responder, ['file1.pdf', 'file2.pdf'])
      expect(state_machine).to have_received(:trigger!).with(
                                 :add_responses,
                                 user_id:     responder.id,
                                 filenames:   ['file1.pdf', 'file2.pdf'],
                                 event:       :add_responses
                               )
    end
  end

  describe '#add_responses' do
    before do
      state_machine.assign_responder!(manager.id, responder.id)
      state_machine.accept_responder_assignment!(responder.id)
    end

    it_behaves_like 'a case state machine event' do
      let(:event_name) { :add_responses                   }
      let(:args) { [responder.id, ['file1.pdf', 'file2.pdf']] }
    end
  end

  describe '#respond!' do

    let(:kase)          { create(:case_with_response) }
    let(:state_machine) { kase.state_machine                   }
    before { state_machine.respond!(responder.id)                }

    it 'triggers a respond event' do
      expect(kase.current_state).to eq 'responded'
    end

    it 'triggers the correct event transition' do
      allow(state_machine).to receive(:trigger!)
      state_machine.respond!(responder.id)
      expect(state_machine).to have_received(:trigger!).with(
                                 :respond,
                                 assignee_id: responder.id,
                                 user_id:     responder.id,
                                 event:       :respond
                               )
    end
  end

  describe '#respond' do
    let(:kase)          { create(:case_with_response)  }
    let(:state_machine) { kase.state_machine                    }

    it_behaves_like 'a case state machine event' do
      let(:event_name) { :respond     }
      let(:args)       { [responder.id] }
    end
  end

  describe '#close!' do

    let(:kase)          { create(:responded_case) }
    let(:state_machine) { kase.state_machine      }
    before { state_machine.close!(manager.id)    }

    it 'triggers a close event' do
      expect(kase.current_state).to eq 'closed'
    end

    it 'triggers the correct event transition' do
      allow(state_machine).to receive(:trigger!)
      state_machine.close!(manager.id)
      expect(state_machine).to have_received(:trigger!).with(
                                 :close,
                                 user_id: manager.id,
                                 event: :close
                               )
    end
  end

  describe '#close' do
    let(:kase)          { create(:responded_case) }
    let(:state_machine) { kase.state_machine      }

    it_behaves_like 'a case state machine event' do
      let(:event_name) { :close      }
      let(:args)       { [manager.id] }
    end
  end

end
