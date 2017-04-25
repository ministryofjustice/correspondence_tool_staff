require 'rails_helper'

RSpec.describe Case, type: :model do
  let(:kase) { create :case }

  describe 'case states' do
    let(:managing_team)   { create :managing_team }
    let(:manager)         { managing_team.managers.first }
    let(:assigned_case)   { create :assigned_case }

    describe '#state_machine' do
      subject { kase.state_machine }

      it { should be_an_instance_of(CaseStateMachine) }
      it { should have_attributes(object: kase)}
    end

    describe '#assign_responder' do
      let(:unassigned_case) { create :case }
      let(:responding_team) { create :responding_team }

      before do
        allow(unassigned_case.state_machine).to receive(:assign_responder)
      end

      it 'creates an assign_responder transition' do
        unassigned_case.assign_responder manager, responding_team
        expect(unassigned_case.state_machine)
          .to have_received(:assign_responder)
                .with manager,
                      managing_team,
                      responding_team
      end
    end

    describe '#flag_for_clearance' do
      let(:state_machine) { assigned_case.state_machine }

      before do
        allow(state_machine).to receive(:flag_for_clearance).with(manager)
      end

      it 'sets requires_attribute to true' do
        expect(assigned_case.requires_clearance?).to eq false
        assigned_case.flag_for_clearance manager
        expect(assigned_case.requires_clearance?).to eq true
      end

      it 'creates a state transition' do
        assigned_case.flag_for_clearance manager
        expect(state_machine).to have_received(:flag_for_clearance).with(manager)
      end
    end

    describe '#responder_assignment_rejected' do
      let(:state_machine)   { assigned_case.state_machine }
      let(:assignment)      { assigned_case.responder_assignment }
      let(:responding_team) { assignment.team }
      let(:responder)       { assignment.team.responders.first }
      let(:message)         { |example| "test #{example.description}" }

      before do
        allow(state_machine).to receive(:reject_responder_assignment)
        allow(state_machine).to receive(:reject_responder_assignment!)
      end

      it 'triggers the raising version of the event' do
        assigned_case.
          responder_assignment_rejected(responder, responding_team, message)
        expect(state_machine).to have_received(:reject_responder_assignment!).
                                   with(responder, responding_team, message)
        expect(state_machine).
          not_to have_received(:reject_responder_assignment)
      end
    end

    describe '#responder_assignment_accepted' do
      let(:assigned_case)   { create :assigned_case }
      let(:state_machine)   { assigned_case.state_machine }
      let(:assignment)      { assigned_case.responder_assignment }
      let(:responding_team) { assignment.team }
      let(:responder)       { assignment.team.responders.first }

      before do
        allow(state_machine).to receive(:accept_responder_assignment)
        allow(state_machine).to receive(:accept_responder_assignment!)
      end

      it 'triggers the raising version of the event' do
        assigned_case.responder_assignment_accepted(responder, responding_team)
        expect(state_machine).to have_received(:accept_responder_assignment!).
                                   with(responder, responding_team)
        expect(state_machine).
          not_to have_received(:accept_responder_assignment)
      end
    end

    describe '#add_responses' do
      let(:accepted_case)   { create(:accepted_case)                          }
      let(:state_machine)   { accepted_case.state_machine                     }
      let(:assignment)      { accepted_case.responder_assignment }
      let(:responding_team) { assignment.team }
      let(:responder)       { assignment.team.responders.first }
      let(:responses)     do
        [
          build(
            :case_response,
            key: "#{SecureRandom.hex(16)}/responses/new response.pdf"
          )
        ]
      end


      context 'with mocked state machine calls' do
        before do
          allow(state_machine).to receive(:add_responses)
          allow(state_machine).to receive(:add_responses!)
        end

        it 'triggers the raising version of the event' do
          accepted_case.add_responses(responder, responses)
          expect(state_machine).to have_received(:add_responses!).
                                     with(responder,
                                          responding_team,
                                          ['new response.pdf'])
          expect(state_machine).
            not_to have_received(:add_responses)
        end

        it 'adds responses to case#attachments' do
          accepted_case.add_responses(responder.id, responses)
          expect(accepted_case.attachments).to match_array(responses)
        end
      end

      context 'with real state machine calls' do
        it 'changes the state from drafting to awaiting_dispatch' do
          expect(accepted_case.current_state).to eq 'drafting'
          accepted_case.add_responses(responder, responses)
          expect(accepted_case.current_state).to eq 'awaiting_dispatch'
        end
      end
    end

    describe '#respond' do
      let(:case_with_response) { create(:case_with_response)      }
      let(:state_machine)      { case_with_response.state_machine }

      before do
        allow(state_machine).to receive(:respond!)
        allow(state_machine).to receive(:respond)
      end

      it 'triggers the raising version of the event' do
        case_with_response.respond(case_with_response.responder)
        expect(state_machine).to have_received(:respond!)
                                   .with(case_with_response.responder,
                                         case_with_response.responding_team)
        expect(state_machine).not_to have_received(:respond)
      end
    end

    describe '#close' do
      let(:responded_case)  { create(:responded_case)      }
      let(:state_machine)   { responded_case.state_machine }

      before do
        allow(state_machine).to receive(:close!)
        allow(state_machine).to receive(:close)
      end

      it 'triggers the raising version of the event' do
        manager = responded_case.managing_team.managers.first
        responded_case.close(manager)
        expect(state_machine).to have_received(:close!)
                                   .with(manager, responded_case.managing_team)
        expect(state_machine).not_to have_received(:close)
      end
    end

    describe '#within_external_deadline?' do
      let(:foi) { create :category, :foi }
      let(:responded_case) do
        create :responded_case,
               category: foi,
               received_date: days_taken.business_days.ago,
               date_responded: Time.first_business_day(Date.today)
      end

      context 'the date responded is before the external deadline' do
        let(:days_taken) { foi.external_time_limit - 1 }

        it 'returns true' do
          expect(responded_case.within_external_deadline?).to eq true
        end
      end

      context 'the date responded is before on external deadline' do
        let(:days_taken) { foi.external_time_limit - 1 }

        it 'returns true' do
          expect(responded_case.within_external_deadline?).to eq true
        end
      end

      context 'the date responded is after the external deadline' do
        let(:days_taken) { foi.external_time_limit + 1 }

        it 'returns false' do
          expect(responded_case.within_external_deadline?).to eq false
        end
      end
    end

    context 'initial state' do
      it 'is set to unassigned' do
        kase = build(:case)
        expect(kase.current_state).to be_nil
        kase.save!
        expect(kase.current_state).to eq 'unassigned'
      end
    end
  end
end
