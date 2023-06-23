require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe "state machine" do
  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end

  context "when usual suspects" do
    before(:all) do
      DbHousekeeping.clean
      @setup = StandardSetup.new(
        only_cases: %i[
          ico_foi_unassigned
          ico_foi_awaiting_responder
          ico_foi_accepted
          ico_foi_pending_dacu
          ico_foi_awaiting_dispatch
          ico_foi_responded
          ico_foi_closed
          ico_sar_unassigned
          ico_sar_awaiting_responder
          ico_sar_accepted
          ico_sar_pending_dacu
          ico_sar_awaiting_dispatch
          ico_sar_responded
          ico_sar_closed
        ],
      )
    end

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe "setup" do
      context "when FOI" do
        context "and trigger workflow" do
          context "and awaiting dispatch" do
            it "is trigger workflow" do
              kase = @setup.ico_sar_awaiting_dispatch
              expect(kase.current_state).to eq "awaiting_dispatch"
              expect(kase.workflow).to eq "trigger"
              expect(kase.approver_assignments.for_team(@setup.disclosure_team).first.state).to eq "accepted"
              expect(kase.approver_assignments.for_team(@setup.press_office_team)).to be_empty
              expect(kase.approver_assignments.for_team(@setup.private_office_team)).to be_empty
            end
          end

          context "and pending dacu clearance" do
            it "is trigger workflow" do
              kase = @setup.ico_foi_pending_dacu
              expect(kase.current_state).to eq "pending_dacu_clearance"
              expect(kase.workflow).to eq "trigger"
              expect(kase.approver_assignments.for_team(@setup.disclosure_team).first.state).to eq "accepted"
              expect(kase.approver_assignments.for_team(@setup.press_office_team)).to be_empty
              expect(kase.approver_assignments.for_team(@setup.private_office_team)).to be_empty
            end
          end
        end
      end
    end

    describe "accept_approver_assignment" do
      let(:event) { :accept_approver_assignment }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist ico_foi_unassigned],
          %i[disclosure_specialist ico_foi_awaiting_responder],
          %i[disclosure_specialist ico_foi_accepted],
          %i[disclosure_specialist ico_sar_unassigned],
          %i[disclosure_specialist ico_sar_awaiting_responder],
          %i[disclosure_specialist ico_sar_accepted],
          %i[disclosure_specialist_coworker ico_foi_unassigned],
          %i[disclosure_specialist_coworker ico_foi_awaiting_responder],
          %i[disclosure_specialist_coworker ico_foi_accepted],
          %i[disclosure_specialist_coworker ico_sar_unassigned],
          %i[disclosure_specialist_coworker ico_sar_awaiting_responder],
          %i[disclosure_specialist_coworker ico_sar_accepted],
        )
      }
    end

    describe "accept_responder_assignment" do
      let(:event) { :accept_responder_assignment }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[responder ico_foi_awaiting_responder],
          %i[sar_responder ico_sar_awaiting_responder],
          %i[another_responder_in_same_team ico_foi_awaiting_responder],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_responder],
        )
      }
    end

    describe "add_message_to_case" do
      let(:event) { :add_message_to_case }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt ico_foi_unassigned],
          %i[disclosure_bmt ico_foi_awaiting_responder],
          %i[disclosure_bmt ico_foi_accepted],
          %i[disclosure_bmt ico_foi_pending_dacu],
          %i[disclosure_bmt ico_foi_awaiting_dispatch],
          %i[disclosure_bmt ico_foi_responded],
          %i[disclosure_bmt ico_foi_closed],
          %i[disclosure_bmt ico_sar_unassigned],
          %i[disclosure_bmt ico_sar_awaiting_responder],
          %i[disclosure_bmt ico_sar_accepted],
          %i[disclosure_bmt ico_sar_pending_dacu],
          %i[disclosure_bmt ico_sar_awaiting_dispatch],
          %i[disclosure_bmt ico_sar_responded],
          %i[disclosure_bmt ico_sar_closed],
          %i[responder ico_foi_awaiting_responder],
          %i[responder ico_foi_accepted],
          %i[responder ico_foi_pending_dacu],
          %i[responder ico_foi_awaiting_dispatch],
          %i[responder ico_foi_responded],
          %i[responder ico_foi_closed],
          %i[sar_responder ico_sar_awaiting_responder],
          %i[sar_responder ico_sar_accepted],
          %i[sar_responder ico_sar_pending_dacu],
          %i[sar_responder ico_sar_awaiting_dispatch],
          %i[sar_responder ico_sar_responded],
          %i[sar_responder ico_sar_closed],
          %i[another_responder_in_same_team ico_foi_awaiting_responder],
          %i[another_responder_in_same_team ico_foi_accepted],
          %i[another_responder_in_same_team ico_foi_pending_dacu],
          %i[another_responder_in_same_team ico_foi_awaiting_dispatch],
          %i[another_responder_in_same_team ico_foi_responded],
          %i[another_responder_in_same_team ico_foi_closed],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_responder],
          %i[another_sar_responder_in_same_team ico_sar_accepted],
          %i[another_sar_responder_in_same_team ico_sar_pending_dacu],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_dispatch],
          %i[another_sar_responder_in_same_team ico_sar_responded],
          %i[another_sar_responder_in_same_team ico_sar_closed],
          %i[disclosure_specialist ico_foi_unassigned],
          %i[disclosure_specialist ico_foi_awaiting_responder],
          %i[disclosure_specialist ico_foi_accepted],
          %i[disclosure_specialist ico_foi_pending_dacu],
          %i[disclosure_specialist ico_foi_awaiting_dispatch],
          %i[disclosure_specialist ico_foi_responded],
          %i[disclosure_specialist ico_foi_closed],
          %i[disclosure_specialist ico_sar_unassigned],
          %i[disclosure_specialist ico_sar_awaiting_responder],
          %i[disclosure_specialist ico_sar_accepted],
          %i[disclosure_specialist ico_sar_pending_dacu],
          %i[disclosure_specialist ico_sar_awaiting_dispatch],
          %i[disclosure_specialist ico_sar_responded],
          %i[disclosure_specialist ico_sar_closed],
          %i[disclosure_specialist_coworker ico_foi_unassigned],
          %i[disclosure_specialist_coworker ico_foi_awaiting_responder],
          %i[disclosure_specialist_coworker ico_foi_accepted],
          %i[disclosure_specialist_coworker ico_foi_pending_dacu],
          %i[disclosure_specialist_coworker ico_foi_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_foi_responded],
          %i[disclosure_specialist_coworker ico_foi_closed],
          %i[disclosure_specialist_coworker ico_sar_unassigned],
          %i[disclosure_specialist_coworker ico_sar_awaiting_responder],
          %i[disclosure_specialist_coworker ico_sar_accepted],
          %i[disclosure_specialist_coworker ico_sar_pending_dacu],
          %i[disclosure_specialist_coworker ico_sar_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_sar_responded],
          %i[disclosure_specialist_coworker ico_sar_closed],
        )
      }

      it {
        expect(event).to have_after_hook(
          %i[disclosure_bmt ico_foi_accepted],
          %i[disclosure_bmt ico_foi_pending_dacu],
          %i[disclosure_bmt ico_foi_awaiting_dispatch],
          %i[disclosure_bmt ico_foi_responded],
          %i[disclosure_bmt ico_sar_accepted],
          %i[disclosure_bmt ico_sar_pending_dacu],
          %i[disclosure_bmt ico_sar_awaiting_dispatch],
          %i[disclosure_bmt ico_sar_responded],
          %i[responder ico_foi_accepted],
          %i[responder ico_foi_pending_dacu],
          %i[responder ico_foi_awaiting_dispatch],
          %i[responder ico_foi_responded],
          %i[sar_responder ico_sar_accepted],
          %i[sar_responder ico_sar_pending_dacu],
          %i[sar_responder ico_sar_awaiting_dispatch],
          %i[sar_responder ico_sar_responded],
          %i[another_responder_in_same_team ico_foi_accepted],
          %i[another_responder_in_same_team ico_foi_pending_dacu],
          %i[another_responder_in_same_team ico_foi_awaiting_dispatch],
          %i[another_responder_in_same_team ico_foi_responded],
          %i[another_sar_responder_in_same_team ico_sar_accepted],
          %i[another_sar_responder_in_same_team ico_sar_pending_dacu],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_dispatch],
          %i[another_sar_responder_in_same_team ico_sar_responded],
          %i[disclosure_specialist ico_foi_accepted],
          %i[disclosure_specialist ico_foi_pending_dacu],
          %i[disclosure_specialist ico_foi_awaiting_dispatch],
          %i[disclosure_specialist ico_foi_responded],
          %i[disclosure_specialist ico_sar_accepted],
          %i[disclosure_specialist ico_sar_pending_dacu],
          %i[disclosure_specialist ico_sar_awaiting_dispatch],
          %i[disclosure_specialist ico_sar_responded],
          %i[disclosure_specialist_coworker ico_foi_accepted],
          %i[disclosure_specialist_coworker ico_foi_pending_dacu],
          %i[disclosure_specialist_coworker ico_foi_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_foi_responded],
          %i[disclosure_specialist_coworker ico_sar_accepted],
          %i[disclosure_specialist_coworker ico_sar_pending_dacu],
          %i[disclosure_specialist_coworker ico_sar_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_sar_responded],
        ).with_hook("Workflows::Hooks", :notify_responder_message_received)
      }
    end

    describe "approve" do
      let(:event) { :approve }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist ico_foi_pending_dacu],
          %i[disclosure_specialist ico_sar_pending_dacu],
        )
      }

      it {
        expect(event).to have_after_hook(
          %i[disclosure_specialist ico_sar_pending_dacu],
          %i[disclosure_specialist ico_foi_pending_dacu],
        ).with_hook("Workflows::Hooks", :notify_responder_ready_to_send)
      }
    end

    describe "assign_responder" do
      let(:event) { :assign_responder }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt ico_foi_unassigned],
          %i[disclosure_bmt ico_sar_unassigned],
        )
      }

      it {
        expect(event).to have_after_hook(
          %i[disclosure_bmt ico_foi_unassigned],
          %i[disclosure_bmt ico_sar_unassigned],
        ).with_hook("Workflows::Hooks", :assign_responder_email)
      }
    end

    describe "assign_to_new_team" do
      let(:event) { :assign_to_new_team }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt ico_foi_awaiting_responder],
          %i[disclosure_bmt ico_foi_accepted],
          %i[disclosure_bmt ico_foi_closed],
          %i[disclosure_bmt ico_sar_awaiting_responder],
          %i[disclosure_bmt ico_sar_accepted],
          %i[disclosure_bmt ico_sar_closed],
        )
      }

      it {
        expect(event).to have_after_hook(
          %i[disclosure_bmt ico_foi_awaiting_responder],
          %i[disclosure_bmt ico_foi_accepted],
          %i[disclosure_bmt ico_sar_awaiting_responder],
          %i[disclosure_bmt ico_sar_accepted],
        ).with_hook("Workflows::Hooks", :assign_responder_email)
      }
    end

    describe "close" do
      let(:event) { :close }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt ico_foi_responded],
          %i[disclosure_bmt ico_sar_responded],
        )
      }
    end

    describe "destroy_case" do
      let(:event) { :destroy_case }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt ico_foi_unassigned],
          %i[disclosure_bmt ico_foi_awaiting_responder],
          %i[disclosure_bmt ico_foi_accepted],
          %i[disclosure_bmt ico_foi_pending_dacu],
          %i[disclosure_bmt ico_foi_awaiting_dispatch],
          %i[disclosure_bmt ico_foi_responded],
          %i[disclosure_bmt ico_foi_closed],
          %i[disclosure_bmt ico_sar_unassigned],
          %i[disclosure_bmt ico_sar_awaiting_responder],
          %i[disclosure_bmt ico_sar_accepted],
          %i[disclosure_bmt ico_sar_pending_dacu],
          %i[disclosure_bmt ico_sar_awaiting_dispatch],
          %i[disclosure_bmt ico_sar_responded],
          %i[disclosure_bmt ico_sar_closed],
        )
      }
    end

    describe "edit_case" do
      let(:event) { :edit_case }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt ico_foi_unassigned],
          %i[disclosure_bmt ico_foi_awaiting_responder],
          %i[disclosure_bmt ico_foi_accepted],
          %i[disclosure_bmt ico_foi_pending_dacu],
          %i[disclosure_bmt ico_foi_awaiting_dispatch],
          %i[disclosure_bmt ico_foi_responded],
          %i[disclosure_bmt ico_foi_closed],
          %i[disclosure_bmt ico_sar_unassigned],
          %i[disclosure_bmt ico_sar_awaiting_responder],
          %i[disclosure_bmt ico_sar_accepted],
          %i[disclosure_bmt ico_sar_pending_dacu],
          %i[disclosure_bmt ico_sar_awaiting_dispatch],
          %i[disclosure_bmt ico_sar_responded],
          %i[disclosure_bmt ico_sar_closed],
        )
      }
    end

    describe "flag_for_clearance" do
      let(:event) { :flag_for_clearance }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt ico_foi_unassigned],
          %i[disclosure_bmt ico_sar_unassigned],
        )
      }
    end

    describe "link_a_case" do
      let(:event) { :link_a_case }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt ico_foi_unassigned],
          %i[disclosure_bmt ico_foi_awaiting_responder],
          %i[disclosure_bmt ico_foi_accepted],
          %i[disclosure_bmt ico_foi_pending_dacu],
          %i[disclosure_bmt ico_foi_awaiting_dispatch],
          %i[disclosure_bmt ico_foi_responded],
          %i[disclosure_bmt ico_foi_closed],
          %i[disclosure_bmt ico_sar_unassigned],
          %i[disclosure_bmt ico_sar_awaiting_responder],
          %i[disclosure_bmt ico_sar_accepted],
          %i[disclosure_bmt ico_sar_pending_dacu],
          %i[disclosure_bmt ico_sar_awaiting_dispatch],
          %i[disclosure_bmt ico_sar_responded],
          %i[disclosure_bmt ico_sar_closed],
          # Responders should not be adding/removing links
          %i[responder ico_foi_unassigned],
          %i[responder ico_foi_awaiting_responder],
          %i[responder ico_foi_accepted],
          %i[responder ico_foi_pending_dacu],
          %i[responder ico_foi_awaiting_dispatch],
          %i[responder ico_foi_responded],
          %i[responder ico_foi_closed],
          %i[responder ico_sar_unassigned],
          %i[responder ico_sar_awaiting_responder],
          %i[responder ico_sar_accepted],
          %i[responder ico_sar_pending_dacu],
          %i[responder ico_sar_awaiting_dispatch],
          %i[responder ico_sar_responded],
          %i[responder ico_sar_closed],
          %i[sar_responder ico_sar_unassigned],
          %i[sar_responder ico_sar_awaiting_responder],
          %i[sar_responder ico_sar_accepted],
          %i[sar_responder ico_sar_pending_dacu],
          %i[sar_responder ico_sar_awaiting_dispatch],
          %i[sar_responder ico_sar_responded],
          %i[sar_responder ico_sar_closed],
          %i[sar_responder ico_foi_unassigned],
          %i[sar_responder ico_foi_awaiting_responder],
          %i[sar_responder ico_foi_accepted],
          %i[sar_responder ico_foi_pending_dacu],
          %i[sar_responder ico_foi_awaiting_dispatch],
          %i[sar_responder ico_foi_responded],
          %i[sar_responder ico_foi_closed],
          # Responders should not be adding/removing links
          %i[another_responder_in_same_team ico_foi_unassigned],
          %i[another_responder_in_same_team ico_foi_awaiting_responder],
          %i[another_responder_in_same_team ico_foi_accepted],
          %i[another_responder_in_same_team ico_foi_pending_dacu],
          %i[another_responder_in_same_team ico_foi_awaiting_dispatch],
          %i[another_responder_in_same_team ico_foi_responded],
          %i[another_responder_in_same_team ico_foi_closed],
          %i[another_responder_in_same_team ico_sar_unassigned],
          %i[another_responder_in_same_team ico_sar_awaiting_responder],
          %i[another_responder_in_same_team ico_sar_accepted],
          %i[another_responder_in_same_team ico_sar_pending_dacu],
          %i[another_responder_in_same_team ico_sar_awaiting_dispatch],
          %i[another_responder_in_same_team ico_sar_responded],
          %i[another_responder_in_same_team ico_sar_closed],
          %i[another_sar_responder_in_same_team ico_sar_unassigned],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_responder],
          %i[another_sar_responder_in_same_team ico_sar_accepted],
          %i[another_sar_responder_in_same_team ico_sar_pending_dacu],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_dispatch],
          %i[another_sar_responder_in_same_team ico_sar_responded],
          %i[another_sar_responder_in_same_team ico_sar_closed],
          %i[another_sar_responder_in_same_team ico_foi_unassigned],
          %i[another_sar_responder_in_same_team ico_foi_awaiting_responder],
          %i[another_sar_responder_in_same_team ico_foi_accepted],
          %i[another_sar_responder_in_same_team ico_foi_pending_dacu],
          %i[another_sar_responder_in_same_team ico_foi_awaiting_dispatch],
          %i[another_sar_responder_in_same_team ico_foi_responded],
          %i[another_sar_responder_in_same_team ico_foi_closed],
          %i[disclosure_specialist ico_foi_unassigned],
          %i[disclosure_specialist ico_foi_awaiting_responder],
          %i[disclosure_specialist ico_foi_accepted],
          %i[disclosure_specialist ico_foi_pending_dacu],
          %i[disclosure_specialist ico_foi_awaiting_dispatch],
          %i[disclosure_specialist ico_foi_responded],
          %i[disclosure_specialist ico_foi_closed],
          %i[disclosure_specialist ico_sar_unassigned],
          %i[disclosure_specialist ico_sar_awaiting_responder],
          %i[disclosure_specialist ico_sar_accepted],
          %i[disclosure_specialist ico_sar_pending_dacu],
          %i[disclosure_specialist ico_sar_awaiting_dispatch],
          %i[disclosure_specialist ico_sar_responded],
          %i[disclosure_specialist ico_sar_closed],
          %i[disclosure_specialist_coworker ico_foi_unassigned],
          %i[disclosure_specialist_coworker ico_foi_awaiting_responder],
          %i[disclosure_specialist_coworker ico_foi_accepted],
          %i[disclosure_specialist_coworker ico_foi_pending_dacu],
          %i[disclosure_specialist_coworker ico_foi_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_foi_responded],
          %i[disclosure_specialist_coworker ico_foi_closed],
          %i[disclosure_specialist_coworker ico_sar_unassigned],
          %i[disclosure_specialist_coworker ico_sar_awaiting_responder],
          %i[disclosure_specialist_coworker ico_sar_accepted],
          %i[disclosure_specialist_coworker ico_sar_pending_dacu],
          %i[disclosure_specialist_coworker ico_sar_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_sar_responded],
          %i[disclosure_specialist_coworker ico_sar_closed],
          %i[another_disclosure_specialist ico_foi_unassigned],
          %i[another_disclosure_specialist ico_foi_awaiting_responder],
          %i[another_disclosure_specialist ico_foi_accepted],
          %i[another_disclosure_specialist ico_foi_pending_dacu],
          %i[another_disclosure_specialist ico_foi_awaiting_dispatch],
          %i[another_disclosure_specialist ico_foi_responded],
          %i[another_disclosure_specialist ico_foi_closed],
          %i[another_disclosure_specialist ico_sar_unassigned],
          %i[another_disclosure_specialist ico_sar_awaiting_responder],
          %i[another_disclosure_specialist ico_sar_accepted],
          %i[another_disclosure_specialist ico_sar_pending_dacu],
          %i[another_disclosure_specialist ico_sar_awaiting_dispatch],
          %i[another_disclosure_specialist ico_sar_responded],
          %i[another_disclosure_specialist ico_sar_closed],
          # Responders should not be adding/removing links
          %i[another_responder_in_diff_team ico_foi_unassigned],
          %i[another_responder_in_diff_team ico_foi_awaiting_responder],
          %i[another_responder_in_diff_team ico_foi_accepted],
          %i[another_responder_in_diff_team ico_foi_pending_dacu],
          %i[another_responder_in_diff_team ico_foi_awaiting_dispatch],
          %i[another_responder_in_diff_team ico_foi_responded],
          %i[another_responder_in_diff_team ico_foi_closed],
          %i[another_responder_in_diff_team ico_sar_unassigned],
          %i[another_responder_in_diff_team ico_sar_awaiting_responder],
          %i[another_responder_in_diff_team ico_sar_accepted],
          %i[another_responder_in_diff_team ico_sar_pending_dacu],
          %i[another_responder_in_diff_team ico_sar_awaiting_dispatch],
          %i[another_responder_in_diff_team ico_sar_responded],
          %i[another_responder_in_diff_team ico_sar_closed],
          %i[another_sar_responder_in_diff_team ico_sar_unassigned],
          %i[another_sar_responder_in_diff_team ico_sar_awaiting_responder],
          %i[another_sar_responder_in_diff_team ico_sar_accepted],
          %i[another_sar_responder_in_diff_team ico_sar_pending_dacu],
          %i[another_sar_responder_in_diff_team ico_sar_awaiting_dispatch],
          %i[another_sar_responder_in_diff_team ico_sar_responded],
          %i[another_sar_responder_in_diff_team ico_sar_closed],
          %i[another_sar_responder_in_diff_team ico_foi_unassigned],
          %i[another_sar_responder_in_diff_team ico_foi_awaiting_responder],
          %i[another_sar_responder_in_diff_team ico_foi_accepted],
          %i[another_sar_responder_in_diff_team ico_foi_pending_dacu],
          %i[another_sar_responder_in_diff_team ico_foi_awaiting_dispatch],
          %i[another_sar_responder_in_diff_team ico_foi_responded],
          %i[another_sar_responder_in_diff_team ico_foi_closed],
          %i[private_officer ico_foi_unassigned],
          %i[private_officer ico_foi_awaiting_responder],
          %i[private_officer ico_foi_accepted],
          %i[private_officer ico_foi_pending_dacu],
          %i[private_officer ico_foi_awaiting_dispatch],
          %i[private_officer ico_foi_responded],
          %i[private_officer ico_foi_closed],
          %i[private_officer ico_sar_unassigned],
          %i[private_officer ico_sar_awaiting_responder],
          %i[private_officer ico_sar_accepted],
          %i[private_officer ico_sar_pending_dacu],
          %i[private_officer ico_sar_awaiting_dispatch],
          %i[private_officer ico_sar_responded],
          %i[private_officer ico_sar_closed],
          %i[press_officer ico_foi_unassigned],
          %i[press_officer ico_foi_awaiting_responder],
          %i[press_officer ico_foi_accepted],
          %i[press_officer ico_foi_pending_dacu],
          %i[press_officer ico_foi_awaiting_dispatch],
          %i[press_officer ico_foi_responded],
          %i[press_officer ico_foi_closed],
          %i[press_officer ico_sar_unassigned],
          %i[press_officer ico_sar_awaiting_responder],
          %i[press_officer ico_sar_accepted],
          %i[press_officer ico_sar_pending_dacu],
          %i[press_officer ico_sar_awaiting_dispatch],
          %i[press_officer ico_sar_responded],
          %i[press_officer ico_sar_closed],
        )
      }
    end

    describe "reassign_user" do
      let(:event) { :reassign_user }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[responder ico_foi_accepted],
          %i[sar_responder ico_sar_accepted],
          %i[responder ico_foi_pending_dacu],
          %i[sar_responder ico_sar_pending_dacu],
          %i[responder ico_foi_awaiting_dispatch],
          %i[sar_responder ico_sar_awaiting_dispatch],
          %i[another_responder_in_same_team ico_foi_accepted],
          %i[another_sar_responder_in_same_team ico_sar_accepted],
          %i[another_responder_in_same_team ico_foi_pending_dacu],
          %i[another_sar_responder_in_same_team ico_sar_pending_dacu],
          %i[another_responder_in_same_team ico_foi_awaiting_dispatch],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_dispatch],
          %i[disclosure_specialist ico_foi_unassigned],
          %i[disclosure_specialist ico_foi_awaiting_responder],
          %i[disclosure_specialist ico_foi_accepted],
          %i[disclosure_specialist ico_foi_pending_dacu],
          %i[disclosure_specialist ico_foi_awaiting_dispatch],
          %i[disclosure_specialist ico_sar_unassigned],
          %i[disclosure_specialist ico_sar_awaiting_responder],
          %i[disclosure_specialist ico_sar_accepted],
          %i[disclosure_specialist ico_sar_pending_dacu],
          %i[disclosure_specialist ico_sar_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_foi_unassigned],
          %i[disclosure_specialist_coworker ico_foi_awaiting_responder],
          %i[disclosure_specialist_coworker ico_foi_accepted],
          %i[disclosure_specialist_coworker ico_foi_pending_dacu],
          %i[disclosure_specialist_coworker ico_foi_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_sar_unassigned],
          %i[disclosure_specialist_coworker ico_sar_awaiting_responder],
          %i[disclosure_specialist_coworker ico_sar_accepted],
          %i[disclosure_specialist_coworker ico_sar_pending_dacu],
          %i[disclosure_specialist_coworker ico_sar_awaiting_dispatch],
        )
      }

      it {
        expect(event).to have_after_hook(
          %i[responder ico_foi_accepted],
          %i[responder ico_foi_pending_dacu],
          %i[responder ico_foi_awaiting_dispatch],
          %i[sar_responder ico_sar_accepted],
          %i[sar_responder ico_sar_pending_dacu],
          %i[sar_responder ico_sar_awaiting_dispatch],
          %i[another_responder_in_same_team ico_foi_accepted],
          %i[another_responder_in_same_team ico_foi_pending_dacu],
          %i[another_responder_in_same_team ico_foi_awaiting_dispatch],
          %i[another_sar_responder_in_same_team ico_sar_accepted],
          %i[another_sar_responder_in_same_team ico_sar_pending_dacu],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_dispatch],
          %i[disclosure_specialist ico_foi_unassigned],
          %i[disclosure_specialist ico_foi_awaiting_responder],
          %i[disclosure_specialist ico_foi_accepted],
          %i[disclosure_specialist ico_foi_pending_dacu],
          %i[disclosure_specialist ico_foi_awaiting_dispatch],
          %i[disclosure_specialist ico_sar_unassigned],
          %i[disclosure_specialist ico_sar_awaiting_responder],
          %i[disclosure_specialist ico_sar_accepted],
          %i[disclosure_specialist ico_sar_pending_dacu],
          %i[disclosure_specialist ico_sar_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_foi_unassigned],
          %i[disclosure_specialist_coworker ico_foi_awaiting_responder],
          %i[disclosure_specialist_coworker ico_foi_accepted],
          %i[disclosure_specialist_coworker ico_foi_pending_dacu],
          %i[disclosure_specialist_coworker ico_foi_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_sar_unassigned],
          %i[disclosure_specialist_coworker ico_sar_awaiting_responder],
          %i[disclosure_specialist_coworker ico_sar_accepted],
          %i[disclosure_specialist_coworker ico_sar_pending_dacu],
          %i[disclosure_specialist_coworker ico_sar_awaiting_dispatch],
        ).with_hook("Workflows::Hooks", :reassign_user_email)
      }
    end

    describe "reject_responder_assignment" do
      let(:event) { :reject_responder_assignment }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[responder ico_foi_awaiting_responder],
          %i[sar_responder ico_sar_awaiting_responder],
          %i[another_responder_in_same_team ico_foi_awaiting_responder],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_responder],
        )
      }
    end

    describe "remove_linked_case" do
      let(:event) { :remove_linked_case }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt ico_foi_unassigned],
          %i[disclosure_bmt ico_foi_awaiting_responder],
          %i[disclosure_bmt ico_foi_accepted],
          %i[disclosure_bmt ico_foi_pending_dacu],
          %i[disclosure_bmt ico_foi_awaiting_dispatch],
          %i[disclosure_bmt ico_foi_responded],
          %i[disclosure_bmt ico_foi_closed],
          %i[disclosure_bmt ico_sar_unassigned],
          %i[disclosure_bmt ico_sar_awaiting_responder],
          %i[disclosure_bmt ico_sar_accepted],
          %i[disclosure_bmt ico_sar_pending_dacu],
          %i[disclosure_bmt ico_sar_awaiting_dispatch],
          %i[disclosure_bmt ico_sar_responded],
          %i[disclosure_bmt ico_sar_closed],
          # Responders should not be adding/removing links
          %i[responder ico_foi_unassigned],
          %i[responder ico_foi_awaiting_responder],
          %i[responder ico_foi_accepted],
          %i[responder ico_foi_pending_dacu],
          %i[responder ico_foi_awaiting_dispatch],
          %i[responder ico_foi_responded],
          %i[responder ico_foi_closed],
          %i[responder ico_sar_unassigned],
          %i[responder ico_sar_awaiting_responder],
          %i[responder ico_sar_accepted],
          %i[responder ico_sar_pending_dacu],
          %i[responder ico_sar_awaiting_dispatch],
          %i[responder ico_sar_responded],
          %i[responder ico_sar_closed],
          %i[sar_responder ico_sar_unassigned],
          %i[sar_responder ico_sar_awaiting_responder],
          %i[sar_responder ico_sar_accepted],
          %i[sar_responder ico_sar_pending_dacu],
          %i[sar_responder ico_sar_awaiting_dispatch],
          %i[sar_responder ico_sar_responded],
          %i[sar_responder ico_sar_closed],
          %i[sar_responder ico_foi_unassigned],
          %i[sar_responder ico_foi_awaiting_responder],
          %i[sar_responder ico_foi_accepted],
          %i[sar_responder ico_foi_pending_dacu],
          %i[sar_responder ico_foi_awaiting_dispatch],
          %i[sar_responder ico_foi_responded],
          %i[sar_responder ico_foi_closed],
          # Responders should not be adding/removing links
          %i[another_responder_in_same_team ico_foi_unassigned],
          %i[another_responder_in_same_team ico_foi_awaiting_responder],
          %i[another_responder_in_same_team ico_foi_accepted],
          %i[another_responder_in_same_team ico_foi_pending_dacu],
          %i[another_responder_in_same_team ico_foi_awaiting_dispatch],
          %i[another_responder_in_same_team ico_foi_responded],
          %i[another_responder_in_same_team ico_foi_closed],
          %i[another_responder_in_same_team ico_sar_unassigned],
          %i[another_responder_in_same_team ico_sar_awaiting_responder],
          %i[another_responder_in_same_team ico_sar_accepted],
          %i[another_responder_in_same_team ico_sar_pending_dacu],
          %i[another_responder_in_same_team ico_sar_awaiting_dispatch],
          %i[another_responder_in_same_team ico_sar_responded],
          %i[another_responder_in_same_team ico_sar_closed],
          %i[another_sar_responder_in_same_team ico_sar_unassigned],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_responder],
          %i[another_sar_responder_in_same_team ico_sar_accepted],
          %i[another_sar_responder_in_same_team ico_sar_pending_dacu],
          %i[another_sar_responder_in_same_team ico_sar_awaiting_dispatch],
          %i[another_sar_responder_in_same_team ico_sar_responded],
          %i[another_sar_responder_in_same_team ico_sar_closed],
          %i[another_sar_responder_in_same_team ico_foi_unassigned],
          %i[another_sar_responder_in_same_team ico_foi_awaiting_responder],
          %i[another_sar_responder_in_same_team ico_foi_accepted],
          %i[another_sar_responder_in_same_team ico_foi_pending_dacu],
          %i[another_sar_responder_in_same_team ico_foi_awaiting_dispatch],
          %i[another_sar_responder_in_same_team ico_foi_responded],
          %i[another_sar_responder_in_same_team ico_foi_closed],
          %i[disclosure_specialist ico_foi_unassigned],
          %i[disclosure_specialist ico_foi_awaiting_responder],
          %i[disclosure_specialist ico_foi_accepted],
          %i[disclosure_specialist ico_foi_pending_dacu],
          %i[disclosure_specialist ico_foi_awaiting_dispatch],
          %i[disclosure_specialist ico_foi_responded],
          %i[disclosure_specialist ico_foi_closed],
          %i[disclosure_specialist ico_sar_unassigned],
          %i[disclosure_specialist ico_sar_awaiting_responder],
          %i[disclosure_specialist ico_sar_accepted],
          %i[disclosure_specialist ico_sar_pending_dacu],
          %i[disclosure_specialist ico_sar_awaiting_dispatch],
          %i[disclosure_specialist ico_sar_responded],
          %i[disclosure_specialist ico_sar_closed],
          %i[disclosure_specialist_coworker ico_foi_unassigned],
          %i[disclosure_specialist_coworker ico_foi_awaiting_responder],
          %i[disclosure_specialist_coworker ico_foi_accepted],
          %i[disclosure_specialist_coworker ico_foi_pending_dacu],
          %i[disclosure_specialist_coworker ico_foi_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_foi_responded],
          %i[disclosure_specialist_coworker ico_foi_closed],
          %i[disclosure_specialist_coworker ico_sar_unassigned],
          %i[disclosure_specialist_coworker ico_sar_awaiting_responder],
          %i[disclosure_specialist_coworker ico_sar_accepted],
          %i[disclosure_specialist_coworker ico_sar_pending_dacu],
          %i[disclosure_specialist_coworker ico_sar_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_sar_responded],
          %i[disclosure_specialist_coworker ico_sar_closed],
          %i[another_disclosure_specialist ico_foi_unassigned],
          %i[another_disclosure_specialist ico_foi_awaiting_responder],
          %i[another_disclosure_specialist ico_foi_accepted],
          %i[another_disclosure_specialist ico_foi_pending_dacu],
          %i[another_disclosure_specialist ico_foi_awaiting_dispatch],
          %i[another_disclosure_specialist ico_foi_responded],
          %i[another_disclosure_specialist ico_foi_closed],
          %i[another_disclosure_specialist ico_sar_unassigned],
          %i[another_disclosure_specialist ico_sar_awaiting_responder],
          %i[another_disclosure_specialist ico_sar_accepted],
          %i[another_disclosure_specialist ico_sar_pending_dacu],
          %i[another_disclosure_specialist ico_sar_awaiting_dispatch],
          %i[another_disclosure_specialist ico_sar_responded],
          %i[another_disclosure_specialist ico_sar_closed],
          # Responders should not be adding/removing links
          %i[another_responder_in_diff_team ico_foi_unassigned],
          %i[another_responder_in_diff_team ico_foi_awaiting_responder],
          %i[another_responder_in_diff_team ico_foi_accepted],
          %i[another_responder_in_diff_team ico_foi_pending_dacu],
          %i[another_responder_in_diff_team ico_foi_awaiting_dispatch],
          %i[another_responder_in_diff_team ico_foi_responded],
          %i[another_responder_in_diff_team ico_foi_closed],
          %i[another_responder_in_diff_team ico_sar_unassigned],
          %i[another_responder_in_diff_team ico_sar_awaiting_responder],
          %i[another_responder_in_diff_team ico_sar_accepted],
          %i[another_responder_in_diff_team ico_sar_pending_dacu],
          %i[another_responder_in_diff_team ico_sar_awaiting_dispatch],
          %i[another_responder_in_diff_team ico_sar_responded],
          %i[another_responder_in_diff_team ico_sar_closed],
          %i[another_sar_responder_in_diff_team ico_sar_unassigned],
          %i[another_sar_responder_in_diff_team ico_sar_awaiting_responder],
          %i[another_sar_responder_in_diff_team ico_sar_accepted],
          %i[another_sar_responder_in_diff_team ico_sar_pending_dacu],
          %i[another_sar_responder_in_diff_team ico_sar_awaiting_dispatch],
          %i[another_sar_responder_in_diff_team ico_sar_responded],
          %i[another_sar_responder_in_diff_team ico_sar_closed],
          %i[another_sar_responder_in_diff_team ico_foi_unassigned],
          %i[another_sar_responder_in_diff_team ico_foi_awaiting_responder],
          %i[another_sar_responder_in_diff_team ico_foi_accepted],
          %i[another_sar_responder_in_diff_team ico_foi_pending_dacu],
          %i[another_sar_responder_in_diff_team ico_foi_awaiting_dispatch],
          %i[another_sar_responder_in_diff_team ico_foi_responded],
          %i[another_sar_responder_in_diff_team ico_foi_closed],
          %i[private_officer ico_foi_unassigned],
          %i[private_officer ico_foi_awaiting_responder],
          %i[private_officer ico_foi_accepted],
          %i[private_officer ico_foi_pending_dacu],
          %i[private_officer ico_foi_awaiting_dispatch],
          %i[private_officer ico_foi_responded],
          %i[private_officer ico_foi_closed],
          %i[private_officer ico_sar_unassigned],
          %i[private_officer ico_sar_awaiting_responder],
          %i[private_officer ico_sar_accepted],
          %i[private_officer ico_sar_pending_dacu],
          %i[private_officer ico_sar_awaiting_dispatch],
          %i[private_officer ico_sar_responded],
          %i[private_officer ico_sar_closed],
          %i[press_officer ico_foi_unassigned],
          %i[press_officer ico_foi_awaiting_responder],
          %i[press_officer ico_foi_accepted],
          %i[press_officer ico_foi_pending_dacu],
          %i[press_officer ico_foi_awaiting_dispatch],
          %i[press_officer ico_foi_responded],
          %i[press_officer ico_foi_closed],
          %i[press_officer ico_sar_unassigned],
          %i[press_officer ico_sar_awaiting_responder],
          %i[press_officer ico_sar_accepted],
          %i[press_officer ico_sar_pending_dacu],
          %i[press_officer ico_sar_awaiting_dispatch],
          %i[press_officer ico_sar_responded],
          %i[press_officer ico_sar_closed],
        )
      }
    end

    describe "respond" do
      let(:event) { :respond }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist ico_foi_awaiting_dispatch],
          %i[disclosure_specialist ico_sar_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_foi_awaiting_dispatch],
          %i[disclosure_specialist_coworker ico_sar_awaiting_dispatch],
        )
      }
    end

    describe "unaccept_approver_assignment" do
      let(:event) { :unaccept_approver_assignment }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist ico_foi_pending_dacu],
          %i[disclosure_specialist ico_sar_pending_dacu],
        )
      }
    end

    describe "upload_response_and_approve" do
      let(:event) { :upload_response_and_approve }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist ico_foi_pending_dacu],
          %i[disclosure_specialist ico_sar_pending_dacu],
        )
      }

      it {
        expect(event).to have_after_hook(
          %i[disclosure_specialist ico_sar_pending_dacu],
          %i[disclosure_specialist ico_foi_pending_dacu],
        ).with_hook("Workflows::Hooks", :notify_responder_ready_to_send)
      }
    end

    describe "upload_response_and_return_for_redraft" do
      let(:event) { :upload_response_and_return_for_redraft }

      it {
        expect(event).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist ico_foi_pending_dacu],
          %i[disclosure_specialist ico_sar_pending_dacu],
        )
      }

      it {
        expect(event).to have_after_hook(
          %i[disclosure_specialist ico_sar_pending_dacu],
          %i[disclosure_specialist ico_foi_pending_dacu],
        ).with_hook("Workflows::Hooks", :notify_responder_redraft_requested)
      }
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
