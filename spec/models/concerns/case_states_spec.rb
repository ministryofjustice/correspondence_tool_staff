require "rails_helper"

RSpec.describe Case, type: :model do
  let(:kase) { create :assigned_case }

  describe "case states" do
    let(:managing_team)   { create :team_disclosure_bmt }
    let(:manager)         { managing_team.managers.first }
    let(:assigned_case)   { create :assigned_case }
    let(:responding_team) { responder.responding_teams.first }
    let(:responder)       { find_or_create :foi_responder }
    let(:dacu_disclosure) { create :team_dacu_disclosure }

    describe "#responder_assignment_rejected" do
      let(:state_machine)   { assigned_case.state_machine }
      let(:assignment)      { assigned_case.responder_assignment }
      let(:responding_team) { assignment.team }
      let(:responder)       { assignment.team.responders.first }
      let(:message)         { |example| "test #{example.description}" }

      before do
        allow(state_machine).to receive(:reject_responder_assignment)
        allow(state_machine).to receive(:reject_responder_assignment!)
      end

      it "triggers the raising version of the event" do
        assigned_case
          .responder_assignment_rejected(responder, responding_team, message)
        expect(state_machine).to have_received(:reject_responder_assignment!)
                                   .with(acting_user: responder,
                                         acting_team: responding_team,
                                         message:)
        expect(state_machine)
          .not_to have_received(:reject_responder_assignment)
      end
    end

    describe "#responder_assignment_accepted" do
      let(:assigned_case)   { create :assigned_case }
      let(:state_machine)   { assigned_case.state_machine }
      let(:assignment)      { assigned_case.responder_assignment }
      let(:responding_team) { assignment.team }
      let(:responder)       { assignment.team.responders.first }

      before do
        allow(state_machine).to receive(:accept_responder_assignment)
        allow(state_machine).to receive(:accept_responder_assignment!)
      end

      it "triggers the raising version of the event" do
        assigned_case.responder_assignment_accepted(responder, responding_team)
        expect(state_machine).to have_received(:accept_responder_assignment!)
                                   .with(acting_user: responder,
                                         acting_team: responding_team)
        expect(state_machine)
          .not_to have_received(:accept_responder_assignment)
      end
    end

    describe "#remove_response from FOI case" do
      let(:kase) { create :case_with_response, responder: }
      let(:attachment) { kase.attachments.first }
      let(:assigner_id) { 666 }

      context "only one attachemnt" do
        before do
          allow(attachment).to receive(:remove_from_storage_bucket)
        end

        it "removes the attachment" do
          expect(kase.attachments.size).to eq 1
          kase.remove_response(responder, attachment)
          expect(kase.attachments.size).to eq 0
        end

        it "changes the state to drafting" do
          expect(kase.current_state).to eq "awaiting_dispatch"
          kase.remove_response(responder, attachment)
          expect(kase.current_state).to eq "drafting"
        end
      end

      context "two attachments" do
        before do
          kase.attachments << build(:correspondence_response, type: "response")
          allow(attachment).to receive(:remove_from_storage_bucket)
        end

        it "removes one attachment" do
          expect(kase.attachments.size).to eq 2
          kase.remove_response(responder, attachment)
          expect(kase.attachments.size).to eq 1
        end

        it "does not change the state" do
          expect(kase.attachments.size).to eq 2
          expect(kase.current_state).to eq "awaiting_dispatch"
          kase.remove_response(responder, attachment)
          expect(kase.current_state).to eq "awaiting_dispatch"
        end
      end
    end

    describe "#remove_response from SAR case" do
      let(:kase) { create :closed_sar_with_response, managing_team:, manager: }
      let(:attachment) { kase.attachments.first }

      context "two attachments" do
        before do
          kase.attachments << build(:correspondence_response, type: "response")
          allow(attachment).to receive(:remove_from_storage_bucket)
        end

        it "removes attachments" do
          expect(kase.attachments.size).to eq 2
          kase.remove_response(manager, attachment)
          expect(kase.attachments.size).to eq 1
        end

        it "does not change the state" do
          expect(kase.attachments.size).to eq 2
          kase.remove_response(manager, attachment)
          expect(kase.current_state).to eq "closed"
          expect(kase.attachments.size).to eq 1
          kase.remove_response(manager, kase.attachments.first)
          expect(kase.current_state).to eq "closed"
        end
      end
    end

    describe "#respond" do
      let(:case_with_response) { create(:case_with_response)      }
      let(:state_machine)      { case_with_response.state_machine }

      before do
        allow(state_machine).to receive(:respond!)
        allow(state_machine).to receive(:respond)
      end

      it "triggers the raising version of the event" do
        case_with_response.respond(case_with_response.responder)
        expect(state_machine).to have_received(:respond!)
                                   .with(acting_user: case_with_response.responder,
                                         acting_team: case_with_response.responding_team)
        expect(state_machine).not_to have_received(:respond)
      end

      it 'set the date_responded to the date the user triggered "Marked as sent"' do
        case_with_response.respond(case_with_response.responder)
        expect(state_machine).to have_received(:respond!)
                                     .with(acting_user: case_with_response.responder,
                                           acting_team: case_with_response.responding_team)
        expect(state_machine).not_to have_received(:respond)
      end
    end

    describe "#close" do
      let(:responded_case)  { create(:responded_case)      }
      let(:state_machine)   { responded_case.state_machine }

      before do
        allow(state_machine).to receive(:close!)
        allow(state_machine).to receive(:close)
      end

      it "triggers the raising version of the event" do
        manager = responded_case.managing_team.managers.first
        responded_case.close(manager)
        expect(state_machine).to have_received(:close!)
                                   .with(acting_user: manager, acting_team: responded_case.managing_team)
        expect(state_machine).not_to have_received(:close)
      end
    end

    describe "#within_external_deadline?" do
      let(:foi) { find_or_create :foi_correspondence_type }
      let(:responded_case) do
        Timecop.freeze(Date.new(2020, 8, 19)) do
          create :responded_case,
                 received_date: days_taken.business_days.ago,
                 date_responded: Time.first_business_day(Date.today)
        end
      end

      context "the date responded is before the external deadline" do
        let(:days_taken) { foi.external_time_limit - 1 }

        it "returns true" do
          Timecop.freeze(Date.new(2020, 8, 19)) do
            expect(responded_case.within_external_deadline?).to eq true
          end
        end
      end

      context "the date responded is before on external deadline" do
        let(:days_taken) { foi.external_time_limit - 1 }

        it "returns true" do
          Timecop.freeze(Date.new(2020, 8, 19)) do
            expect(responded_case.within_external_deadline?).to eq true
          end
        end
      end

      context "the date responded is after the external deadline" do
        let(:days_taken) { foi.external_time_limit + 1 }

        it "returns false" do
          Timecop.freeze(Date.new(2020, 8, 19)) do
            expect(responded_case.within_external_deadline?).to eq false
          end
        end
      end
    end

    describe "reset_state_machine callback" do
      it "is called when the workflow changes" do
        expect(kase.state_machine).not_to be_nil
        kase.update!(workflow: "trigger")
        expect(kase.instance_variable_get(:@state_machine)).to be_nil
      end
    end

    context "initial state" do
      it "is set to unassigned" do
        kase = build(:case, current_state: nil)
        expect(kase.current_state).to be_nil
        kase.save!
        expect(kase.current_state).to eq "unassigned"
      end
    end
  end

  context "state_machine decisions" do
    context "SAR" do
      it "returns config state machine" do
        kase = create :sar_case
        expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)
      end
    end

    context "FOI::Standard" do
      context "trigger case" do
        context "unassigned state" do
          it "returns configurable state machine" do
            kase = create :case, :flagged, :dacu_disclosure
            expect(kase.current_state).to eq "unassigned"
            expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)
          end
        end

        context "assigned state" do
          it "returns legacy state machine" do
            kase = create :assigned_case, :flagged, :dacu_disclosure
            expect(kase.current_state).to eq "awaiting_responder"
            expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)
          end
        end
      end

      context "non trigger case" do
        context "unassigned state" do
          it "returns configurable state machine" do
            kase = create :case
            expect(kase.current_state).to eq "unassigned"
            expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)
          end
        end

        context "assigned state" do
          it "returns configurable state machine" do
            kase = create :assigned_case
            expect(kase.current_state).to eq "awaiting_responder"
            expect(kase.state_machine).to be_instance_of(ConfigurableStateMachine::Machine)
          end
        end
      end
    end
  end
end
