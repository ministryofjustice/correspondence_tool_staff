require "rails_helper"

describe ConfigurableStateMachine::Machine do # rubocop:disable RSpec/FilePath
  context "when non-flagged case" do
    context "and manager" do
      let(:manager) { create :manager }

      context "and in unassigned state" do
        it "shows permitted events" do
          k = create :sar_case
          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_responder
                                                                        destroy_case
                                                                        edit_case
                                                                        flag_for_clearance
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        request_further_clearance
                                                                        stop_the_clock]
        end
      end

      context "and awaiting responder" do
        it "shows permitted events" do
          k = create :awaiting_responder_sar
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        flag_for_clearance
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        request_further_clearance
                                                                        stop_the_clock]
        end
      end

      context "and drafting" do
        it "shows permitted events" do
          k = create :accepted_sar
          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        extend_sar_deadline
                                                                        flag_for_clearance
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        request_further_clearance
                                                                        stop_the_clock
                                                                        unassign_from_user]
        end
      end

      context "and closed" do
        it "shows permitted events" do
          k = create :closed_sar
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        add_responses
                                                                        assign_to_new_team
                                                                        destroy_case
                                                                        edit_case
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        remove_response
                                                                        update_closure]
        end
      end
    end

    context "and manager in production environment" do
      before do
        feature = instance_double(FeatureSet::EnabledFeature, enabled?: false, disabled?: true)
        allow(FeatureSet).to receive(:stop_the_clock).and_return(feature)
      end

      context "and in unassigned state" do
        let(:manager) { create :manager }

        it "shows permitted events" do
          k = create :sar_case
          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(manager.id)).to eq %i[add_message_to_case
                                                                        assign_responder
                                                                        destroy_case
                                                                        edit_case
                                                                        flag_for_clearance
                                                                        link_a_case
                                                                        remove_linked_case
                                                                        request_further_clearance]
        end
      end
    end

    context "when not in assigned team" do
      let(:responder) { create :responder }

      context "and in unassigned state" do
        it "shows permitted events" do
          k = create :sar_case
          expect(k.current_state).to eq "unassigned"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "when awaiting responder state" do
        it "shows permitted events" do
          k = create :awaiting_responder_sar
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "when drafting state" do
        it "shows permitted events" do
          k = create :accepted_sar
          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end

      context "when closed state" do
        it "shows permitted events" do
          k = create :closed_sar
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(responder.id)).to be_empty
        end
      end
    end

    context "when within assigned team" do
      context "and awaiting responder state" do
        it "shows permitted events" do
          k = create :awaiting_responder_sar
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "awaiting_responder"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[accept_responder_assignment
                                                                          add_message_to_case
                                                                          reject_responder_assignment]
        end
      end

      context "when drafting state" do
        it "shows permitted events" do
          k = create :accepted_sar
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "drafting"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                          close
                                                                          reassign_user
                                                                          respond
                                                                          respond_and_close]
        end
      end

      context "when closed state" do
        it "shows permitted events" do
          k = create :closed_sar
          responder = responder_in_assigned_team(k)
          expect(k.current_state).to eq "closed"
          expect(k.state_machine.permitted_events(responder.id)).to eq %i[add_message_to_case
                                                                          update_closure]
        end
      end
    end

    def responder_in_assigned_team(kase)
      create :responder, responding_teams: [kase.responding_team]
    end
  end
end
