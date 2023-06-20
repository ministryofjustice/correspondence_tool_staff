require "rails_helper"

describe "state machine" do
  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end

  context "with usual suspects" do
    before(:all) do
      DbHousekeeping.clean
      @setup = StandardSetup.new(
        only_cases: %i[
          full_awdis_foi
          full_awresp_foi
          full_awresp_foi_accepted
          full_closed_foi
          full_draft_foi
          full_pdacu_foi_accepted
          full_pdacu_foi_unaccepted
          full_ppress_foi
          full_pprivate_foi
          full_responded_foi
          full_unassigned_foi
          std_awdis_foi
          std_awresp_foi
          std_closed_foi
          std_draft_foi
          std_draft_foi_in_escalation_period
          std_responded_foi
          std_unassigned_foi
          trig_awdis_foi
          trig_awresp_foi
          trig_awresp_foi_accepted
          trig_closed_foi
          trig_draft_foi
          trig_draft_foi_accepted
          trig_pdacu_foi
          trig_pdacu_foi_accepted
          trig_responded_foi
          trig_unassigned_foi
          trig_unassigned_foi_accepted
        ],
      )
    end

    after(:all) { DbHousekeeping.clean }

    let(:disclosure_assignment) do
      kase.assignments.approving.for_team(@setup.disclosure_team).first
    end

    let(:press_assignment) do
      kase.assignments.approving.for_team(@setup.press_office_team).first
    end

    let(:private_assignment) do
      kase.assignments.approving.for_team(@setup.private_office_team).first
    end

    describe "setup" do
      describe "FOI" do
        describe "standard workflow" do
          context "when awaiting dispatch" do
            it "is in awiting dispatch state with no approver assignments" do
              kase = @setup.std_awdis_foi
              expect(kase.current_state).to eq "awaiting_dispatch"
              expect(kase.workflow).to eq "standard"
              expect(kase.approver_assignments).to be_empty
            end
          end
        end

        describe "trigger workflow" do
          context "when awaiting dispatch" do
            let(:kase) { @setup.trig_awdis_foi }

            it "is trigger workflow" do
              expect(kase.current_state).to eq "awaiting_dispatch"
              expect(kase.workflow).to eq "trigger"
              expect(disclosure_assignment.state).to eq "accepted"
              expect(press_assignment).not_to be_present
              expect(private_assignment).not_to be_present
            end
          end
        end

        describe "full_approval workflow" do
          context "when pending dacu clearance" do
            context "and accepted by disclosure specialist" do
              let(:kase) { @setup.full_pdacu_foi_accepted }

              it "accepted by all three approving teams " do
                expect(kase.current_state).to eq "pending_dacu_clearance"
                expect(kase.workflow).to eq "full_approval"
                expect(disclosure_assignment.state).to eq "accepted"
                expect(press_assignment.state).to eq "accepted"
                expect(private_assignment.state).to eq "accepted"
              end
            end

            context "and not accepted yet by dacu disclosure" do
              let(:kase) { @setup.full_pdacu_foi_unaccepted }

              it "accepted by press and private but not disclosure" do
                expect(kase.current_state).to eq "pending_dacu_clearance"
                expect(kase.workflow).to eq "full_approval"
                expect(disclosure_assignment.state).to eq "pending"
                expect(press_assignment.state).to eq "accepted"
                expect(private_assignment.state).to eq "accepted"
              end
            end
          end

          context "when awaiting dispatch" do
            let(:kase) { @setup.full_awdis_foi }

            it "is full approval workflow accepted by press, private and disclosure" do
              expect(kase.current_state).to eq "awaiting_dispatch"
              expect(kase.workflow).to eq "full_approval"
              expect(disclosure_assignment.state).to eq "accepted"
              expect(press_assignment.state).to eq "accepted"
              expect(private_assignment.state).to eq "accepted"
            end
          end
        end
      end
    end

    describe "accept_approver_assignment" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist trig_unassigned_foi],
          %i[disclosure_specialist trig_awresp_foi],
          %i[disclosure_specialist trig_draft_foi],
          %i[disclosure_specialist trig_pdacu_foi],
          %i[disclosure_specialist full_unassigned_foi],
          %i[disclosure_specialist full_awresp_foi],
          %i[disclosure_specialist full_draft_foi],
          %i[disclosure_specialist full_pdacu_foi_unaccepted],
          %i[disclosure_specialist_coworker trig_unassigned_foi],
          %i[disclosure_specialist_coworker trig_awresp_foi],
          %i[disclosure_specialist_coworker trig_draft_foi],
          %i[disclosure_specialist_coworker trig_pdacu_foi],
          %i[disclosure_specialist_coworker full_unassigned_foi],
          %i[disclosure_specialist_coworker full_awresp_foi],
          %i[disclosure_specialist_coworker full_draft_foi],
          %i[disclosure_specialist_coworker full_pdacu_foi_unaccepted],
        )
      }
    end

    describe "accept_responder_assignment" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[responder std_awresp_foi],
          %i[responder trig_awresp_foi],
          %i[responder full_awresp_foi],
          %i[responder trig_awresp_foi_accepted],
          %i[responder full_awresp_foi_accepted],
          %i[another_responder_in_same_team std_awresp_foi],
          %i[another_responder_in_same_team trig_awresp_foi],
          %i[another_responder_in_same_team full_awresp_foi],
          %i[another_responder_in_same_team trig_awresp_foi_accepted],
          %i[another_responder_in_same_team full_awresp_foi_accepted],
        )
      }
    end

    describe "add_message_to_case" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_unassigned_foi],
          %i[disclosure_bmt std_awresp_foi],
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt std_awdis_foi],
          %i[disclosure_bmt std_responded_foi],
          %i[disclosure_bmt std_closed_foi],
          %i[disclosure_bmt trig_unassigned_foi],
          %i[disclosure_bmt trig_awresp_foi],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt trig_pdacu_foi],
          %i[disclosure_bmt trig_awdis_foi],
          %i[disclosure_bmt trig_responded_foi],
          %i[disclosure_bmt trig_closed_foi],
          %i[disclosure_bmt full_unassigned_foi],
          %i[disclosure_bmt full_awresp_foi],
          %i[disclosure_bmt full_draft_foi],
          %i[disclosure_bmt full_ppress_foi],
          %i[disclosure_bmt full_pprivate_foi],
          %i[disclosure_bmt full_awdis_foi],
          %i[disclosure_bmt full_responded_foi],
          %i[disclosure_bmt trig_unassigned_foi_accepted],
          %i[disclosure_bmt trig_awresp_foi_accepted],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt trig_pdacu_foi_accepted],
          %i[disclosure_bmt full_awresp_foi_accepted],
          %i[disclosure_bmt full_pdacu_foi_accepted],
          %i[disclosure_bmt full_pdacu_foi_unaccepted],
          %i[disclosure_bmt full_closed_foi],
          %i[disclosure_specialist std_closed_foi],
          %i[disclosure_specialist trig_unassigned_foi],
          %i[disclosure_specialist trig_awresp_foi],
          %i[disclosure_specialist trig_draft_foi],
          %i[disclosure_specialist trig_pdacu_foi],
          %i[disclosure_specialist trig_awdis_foi],
          %i[disclosure_specialist trig_responded_foi],
          %i[disclosure_specialist trig_unassigned_foi_accepted],
          %i[disclosure_specialist trig_awresp_foi_accepted],
          %i[disclosure_specialist trig_draft_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
          %i[disclosure_specialist trig_closed_foi],
          %i[disclosure_specialist full_awresp_foi_accepted],
          %i[disclosure_specialist full_unassigned_foi],
          %i[disclosure_specialist full_awresp_foi],
          %i[disclosure_specialist full_draft_foi],
          %i[disclosure_specialist full_ppress_foi],
          %i[disclosure_specialist full_pprivate_foi],
          %i[disclosure_specialist full_awdis_foi],
          %i[disclosure_specialist full_responded_foi],
          %i[disclosure_specialist full_pdacu_foi_accepted],
          %i[disclosure_specialist full_pdacu_foi_unaccepted],
          %i[disclosure_specialist full_closed_foi],
          %i[disclosure_specialist_coworker std_closed_foi],
          %i[disclosure_specialist_coworker trig_unassigned_foi],
          %i[disclosure_specialist_coworker trig_awresp_foi],
          %i[disclosure_specialist_coworker trig_draft_foi],
          %i[disclosure_specialist_coworker trig_pdacu_foi],
          %i[disclosure_specialist_coworker trig_unassigned_foi_accepted],
          %i[disclosure_specialist_coworker trig_awresp_foi_accepted],
          %i[disclosure_specialist_coworker trig_draft_foi_accepted],
          %i[disclosure_specialist_coworker trig_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker trig_closed_foi],
          %i[disclosure_specialist_coworker full_awresp_foi_accepted],
          %i[disclosure_specialist_coworker full_unassigned_foi],
          %i[disclosure_specialist_coworker full_awresp_foi],
          %i[disclosure_specialist_coworker full_draft_foi],
          %i[disclosure_specialist_coworker full_ppress_foi],
          %i[disclosure_specialist_coworker full_pprivate_foi],
          %i[disclosure_specialist_coworker full_responded_foi],
          %i[disclosure_specialist_coworker full_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker full_pdacu_foi_unaccepted],
          %i[disclosure_specialist_coworker full_closed_foi],
          %i[another_disclosure_specialist std_closed_foi],
          %i[another_disclosure_specialist trig_awresp_foi],
          %i[another_disclosure_specialist trig_draft_foi],
          %i[another_disclosure_specialist trig_pdacu_foi],
          %i[another_disclosure_specialist trig_closed_foi],
          %i[another_disclosure_specialist trig_awresp_foi_accepted],
          %i[another_disclosure_specialist trig_draft_foi_accepted],
          %i[another_disclosure_specialist trig_pdacu_foi_accepted],
          %i[another_disclosure_specialist full_closed_foi],
          %i[responder std_awresp_foi],
          %i[responder std_draft_foi],
          %i[responder std_draft_foi_in_escalation_period],
          %i[responder std_awdis_foi],
          %i[responder std_responded_foi],
          %i[responder std_closed_foi],
          %i[responder trig_awresp_foi],
          %i[responder trig_draft_foi],
          %i[responder trig_pdacu_foi],
          %i[responder trig_awdis_foi],
          %i[responder trig_responded_foi],
          %i[responder trig_awresp_foi_accepted],
          %i[responder trig_draft_foi_accepted],
          %i[responder trig_pdacu_foi_accepted],
          %i[responder trig_closed_foi],
          %i[responder full_awresp_foi_accepted],
          %i[responder full_awresp_foi],
          %i[responder full_draft_foi],
          %i[responder full_ppress_foi],
          %i[responder full_pprivate_foi],
          %i[responder full_awdis_foi],
          %i[responder full_responded_foi],
          %i[responder full_pdacu_foi_accepted],
          %i[responder full_pdacu_foi_unaccepted],
          %i[responder full_closed_foi],
          %i[sar_responder std_closed_foi],
          %i[sar_responder trig_closed_foi],
          %i[sar_responder full_closed_foi],
          %i[another_responder_in_same_team std_awresp_foi],
          %i[another_responder_in_same_team std_draft_foi],
          %i[another_responder_in_same_team std_draft_foi_in_escalation_period],
          %i[another_responder_in_same_team std_awdis_foi],
          %i[another_responder_in_same_team std_responded_foi],
          %i[another_responder_in_same_team std_closed_foi],
          %i[another_responder_in_same_team trig_awresp_foi],
          %i[another_responder_in_same_team trig_awresp_foi_accepted],
          %i[another_responder_in_same_team trig_draft_foi],
          %i[another_responder_in_same_team trig_draft_foi_accepted],
          %i[another_responder_in_same_team trig_pdacu_foi],
          %i[another_responder_in_same_team trig_pdacu_foi_accepted],
          %i[another_responder_in_same_team trig_awdis_foi],
          %i[another_responder_in_same_team trig_responded_foi],
          %i[another_responder_in_same_team trig_closed_foi],
          %i[another_responder_in_same_team full_awresp_foi],
          %i[another_responder_in_same_team full_awresp_foi_accepted],
          %i[another_responder_in_same_team full_draft_foi],
          %i[another_responder_in_same_team full_ppress_foi],
          %i[another_responder_in_same_team full_pprivate_foi],
          %i[another_responder_in_same_team full_awdis_foi],
          %i[another_responder_in_same_team full_responded_foi],
          %i[another_responder_in_same_team full_pdacu_foi_accepted],
          %i[another_responder_in_same_team full_pdacu_foi_unaccepted],
          %i[another_responder_in_same_team full_closed_foi],
          %i[another_sar_responder_in_same_team std_closed_foi],
          %i[another_sar_responder_in_same_team trig_closed_foi],
          %i[another_sar_responder_in_same_team full_closed_foi],
          %i[another_responder_in_diff_team std_closed_foi],
          %i[another_responder_in_diff_team trig_closed_foi],
          %i[another_responder_in_diff_team full_closed_foi],
          %i[another_sar_responder_in_diff_team std_closed_foi],
          %i[another_sar_responder_in_diff_team trig_closed_foi],
          %i[another_sar_responder_in_diff_team full_closed_foi],
          %i[press_officer std_closed_foi],
          %i[press_officer trig_awresp_foi],
          %i[press_officer trig_draft_foi],
          %i[press_officer trig_pdacu_foi],
          %i[press_officer trig_awresp_foi_accepted],
          %i[press_officer trig_draft_foi_accepted],
          %i[press_officer trig_pdacu_foi_accepted],
          %i[press_officer trig_closed_foi],
          %i[press_officer full_awresp_foi_accepted],
          %i[press_officer full_unassigned_foi],
          %i[press_officer full_awresp_foi],
          %i[press_officer full_draft_foi],
          %i[press_officer full_ppress_foi],
          %i[press_officer full_pprivate_foi],
          %i[press_officer full_responded_foi],
          %i[press_officer full_pdacu_foi_accepted],
          %i[press_officer full_pdacu_foi_unaccepted],
          %i[press_officer full_awdis_foi],
          %i[press_officer full_closed_foi],
          %i[private_officer std_closed_foi],
          %i[private_officer trig_awresp_foi],
          %i[private_officer trig_draft_foi],
          %i[private_officer trig_pdacu_foi],
          %i[private_officer trig_awresp_foi_accepted],
          %i[private_officer trig_draft_foi_accepted],
          %i[private_officer trig_pdacu_foi_accepted],
          %i[private_officer trig_closed_foi],
          %i[private_officer full_awresp_foi_accepted],
          %i[private_officer full_unassigned_foi],
          %i[private_officer full_awresp_foi],
          %i[private_officer full_draft_foi],
          %i[private_officer full_ppress_foi],
          %i[private_officer full_pprivate_foi],
          %i[private_officer full_responded_foi],
          %i[private_officer full_pdacu_foi_accepted],
          %i[private_officer full_pdacu_foi_unaccepted],
          %i[private_officer full_awdis_foi],
          %i[private_officer trig_closed_foi],
          %i[private_officer full_closed_foi],
        )
      }
    end

    describe "add_responses" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist full_awdis_foi],
          %i[responder std_draft_foi],
          %i[responder std_awdis_foi],
          %i[responder trig_draft_foi],
          %i[responder trig_draft_foi_accepted],
          %i[responder trig_awdis_foi],
          %i[responder full_draft_foi],
          %i[responder full_awdis_foi],
          %i[another_responder_in_same_team std_draft_foi],
          %i[another_responder_in_same_team std_awdis_foi],
          %i[another_responder_in_same_team trig_draft_foi],
          %i[another_responder_in_same_team trig_draft_foi_accepted],
          %i[another_responder_in_same_team trig_awdis_foi],
          %i[another_responder_in_same_team full_draft_foi],
          %i[another_responder_in_same_team full_awdis_foi],
        )
      }
    end

    describe "approve" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist trig_pdacu_foi_accepted],
          %i[disclosure_specialist full_pdacu_foi_accepted],
          %i[press_officer full_ppress_foi],
          %i[private_officer full_pprivate_foi],
        )
      }
    end

    describe "approve_and_bypass" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist full_pdacu_foi_accepted],
        )
      }
    end

    describe "assign_responder" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_unassigned_foi],
          %i[disclosure_bmt trig_unassigned_foi_accepted],
          %i[disclosure_bmt trig_unassigned_foi],
          %i[disclosure_bmt full_unassigned_foi],
        )
      }
    end

    describe "assign_to_new_team" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_awresp_foi],
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt std_closed_foi],
          %i[disclosure_bmt trig_awresp_foi],
          %i[disclosure_bmt trig_awresp_foi_accepted],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt trig_closed_foi],
          %i[disclosure_bmt full_awresp_foi],
          %i[disclosure_bmt full_awresp_foi_accepted],
          %i[disclosure_bmt full_draft_foi],
          %i[disclosure_bmt full_closed_foi],
        )
      }
    end

    describe "close" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_responded_foi],
          %i[disclosure_bmt trig_responded_foi],
          %i[disclosure_bmt full_responded_foi],
        )
      }
    end

    describe "destroy_case" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_unassigned_foi],
          %i[disclosure_bmt std_awresp_foi],
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt std_awdis_foi],
          %i[disclosure_bmt std_responded_foi],
          %i[disclosure_bmt std_closed_foi],
          %i[disclosure_bmt trig_unassigned_foi],
          %i[disclosure_bmt trig_unassigned_foi_accepted],
          %i[disclosure_bmt trig_awresp_foi],
          %i[disclosure_bmt trig_awresp_foi_accepted],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt trig_pdacu_foi],
          %i[disclosure_bmt trig_pdacu_foi_accepted],
          %i[disclosure_bmt trig_awdis_foi],
          %i[disclosure_bmt trig_responded_foi],
          %i[disclosure_bmt trig_closed_foi],
          %i[disclosure_bmt full_unassigned_foi],
          %i[disclosure_bmt full_awresp_foi],
          %i[disclosure_bmt full_awresp_foi_accepted],
          %i[disclosure_bmt full_draft_foi],
          %i[disclosure_bmt full_pdacu_foi_accepted],
          %i[disclosure_bmt full_pdacu_foi_unaccepted],
          %i[disclosure_bmt full_ppress_foi],
          %i[disclosure_bmt full_pprivate_foi],
          %i[disclosure_bmt full_awdis_foi],
          %i[disclosure_bmt full_responded_foi],
          %i[disclosure_bmt full_closed_foi],
        )
      }
    end

    describe "edit_case" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_unassigned_foi],
          %i[disclosure_bmt std_awresp_foi],
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt std_awdis_foi],
          %i[disclosure_bmt std_responded_foi],
          %i[disclosure_bmt std_closed_foi],
          %i[disclosure_bmt trig_unassigned_foi],
          %i[disclosure_bmt trig_unassigned_foi_accepted],
          %i[disclosure_bmt trig_awresp_foi],
          %i[disclosure_bmt trig_awresp_foi_accepted],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt trig_pdacu_foi],
          %i[disclosure_bmt trig_pdacu_foi_accepted],
          %i[disclosure_bmt trig_awdis_foi],
          %i[disclosure_bmt trig_responded_foi],
          %i[disclosure_bmt trig_closed_foi],
          %i[disclosure_bmt full_unassigned_foi],
          %i[disclosure_bmt full_awresp_foi],
          %i[disclosure_bmt full_awresp_foi_accepted],
          %i[disclosure_bmt full_draft_foi],
          %i[disclosure_bmt full_pdacu_foi_accepted],
          %i[disclosure_bmt full_pdacu_foi_unaccepted],
          %i[disclosure_bmt full_ppress_foi],
          %i[disclosure_bmt full_pprivate_foi],
          %i[disclosure_bmt full_awdis_foi],
          %i[disclosure_bmt full_responded_foi],
          %i[disclosure_bmt full_closed_foi],
        )
      }
    end

    describe "extend_for_pit" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt std_awdis_foi],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt trig_pdacu_foi_accepted],
          %i[disclosure_bmt trig_pdacu_foi],
          %i[disclosure_bmt trig_awdis_foi],
          %i[disclosure_bmt full_draft_foi],
          %i[disclosure_bmt full_pdacu_foi_unaccepted],
          %i[disclosure_bmt full_pdacu_foi_accepted],
          %i[disclosure_bmt full_ppress_foi],
          %i[disclosure_bmt full_pprivate_foi],
          %i[disclosure_bmt full_awdis_foi],
        )
      }
    end

    describe "flag_for_clearance" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_unassigned_foi],
          %i[disclosure_bmt std_awresp_foi],
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt std_awdis_foi],
          %i[disclosure_bmt trig_unassigned_foi],
          %i[disclosure_bmt trig_awresp_foi],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt full_unassigned_foi],
          %i[disclosure_bmt full_awresp_foi],
          %i[disclosure_bmt full_draft_foi],
          %i[disclosure_bmt trig_unassigned_foi_accepted],
          %i[disclosure_bmt trig_awresp_foi_accepted],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt full_awresp_foi_accepted],
          %i[disclosure_bmt trig_awdis_foi],              # old state machine allows it but shouldn't
          %i[disclosure_bmt full_awdis_foi], # old state machine allows it but shouldn't
          %i[disclosure_specialist std_unassigned_foi],
          %i[disclosure_specialist std_awresp_foi],
          %i[disclosure_specialist std_draft_foi],
          %i[disclosure_specialist std_draft_foi_in_escalation_period],
          %i[disclosure_specialist trig_unassigned_foi],
          %i[disclosure_specialist trig_awresp_foi],
          %i[disclosure_specialist trig_draft_foi],
          %i[disclosure_specialist full_unassigned_foi],
          %i[disclosure_specialist full_awresp_foi],
          %i[disclosure_specialist full_draft_foi],
          %i[disclosure_specialist full_awdis_foi],
          %i[disclosure_specialist trig_unassigned_foi_accepted],
          %i[disclosure_specialist trig_awresp_foi_accepted],
          %i[disclosure_specialist trig_draft_foi_accepted],
          %i[disclosure_specialist full_awresp_foi_accepted],
          %i[disclosure_specialist_coworker std_unassigned_foi],
          %i[disclosure_specialist_coworker std_awresp_foi],
          %i[disclosure_specialist_coworker std_draft_foi],
          %i[disclosure_specialist_coworker std_draft_foi_in_escalation_period],
          %i[disclosure_specialist_coworker trig_unassigned_foi],
          %i[disclosure_specialist_coworker trig_awresp_foi],
          %i[disclosure_specialist_coworker trig_draft_foi],
          %i[disclosure_specialist_coworker full_unassigned_foi],
          %i[disclosure_specialist_coworker full_awresp_foi],
          %i[disclosure_specialist_coworker full_draft_foi],
          %i[disclosure_specialist_coworker full_awdis_foi],
          %i[disclosure_specialist_coworker trig_unassigned_foi_accepted],
          %i[disclosure_specialist_coworker trig_awresp_foi_accepted],
          %i[disclosure_specialist_coworker trig_draft_foi_accepted],
          %i[disclosure_specialist_coworker full_awresp_foi_accepted],
          %i[another_disclosure_specialist std_unassigned_foi],
          %i[another_disclosure_specialist std_awresp_foi],
          %i[another_disclosure_specialist std_draft_foi],
          %i[another_disclosure_specialist std_draft_foi_in_escalation_period],
          %i[another_disclosure_specialist trig_unassigned_foi],
          %i[another_disclosure_specialist trig_awresp_foi],
          %i[another_disclosure_specialist trig_draft_foi],
          %i[another_disclosure_specialist full_unassigned_foi],
          %i[another_disclosure_specialist full_awresp_foi],
          %i[another_disclosure_specialist full_draft_foi],
          %i[another_disclosure_specialist full_awdis_foi],
          %i[another_disclosure_specialist trig_unassigned_foi_accepted],
          %i[another_disclosure_specialist trig_awresp_foi_accepted],
          %i[another_disclosure_specialist trig_draft_foi_accepted],
          %i[another_disclosure_specialist full_awresp_foi_accepted],
          %i[press_officer std_unassigned_foi],
          %i[press_officer std_awresp_foi],
          %i[press_officer std_draft_foi],
          %i[press_officer std_draft_foi_in_escalation_period],
          %i[press_officer trig_unassigned_foi],
          %i[press_officer trig_awresp_foi],
          %i[press_officer trig_draft_foi],
          %i[press_officer full_unassigned_foi],
          %i[press_officer full_awresp_foi],
          %i[press_officer full_draft_foi],
          %i[press_officer trig_unassigned_foi_accepted],
          %i[press_officer trig_awresp_foi_accepted],
          %i[press_officer trig_draft_foi_accepted],
          %i[press_officer full_awresp_foi_accepted],
          %i[press_officer full_awdis_foi],
          %i[private_officer std_unassigned_foi],
          %i[private_officer std_awresp_foi],
          %i[private_officer std_draft_foi],
          %i[private_officer std_draft_foi_in_escalation_period],
          %i[private_officer trig_unassigned_foi],
          %i[private_officer trig_awresp_foi],
          %i[private_officer trig_draft_foi],
          %i[private_officer full_unassigned_foi],
          %i[private_officer full_awresp_foi],
          %i[private_officer full_draft_foi],
          %i[private_officer trig_unassigned_foi_accepted],
          %i[private_officer trig_awresp_foi_accepted],
          %i[private_officer trig_draft_foi_accepted],
          %i[private_officer full_awresp_foi_accepted],
          %i[private_officer full_awdis_foi],
        )
      }
    end

    describe "link_a_case" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_unassigned_foi],
          %i[disclosure_bmt std_awresp_foi],
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt std_awdis_foi],
          %i[disclosure_bmt std_responded_foi],
          %i[disclosure_bmt trig_unassigned_foi],
          %i[disclosure_bmt trig_awresp_foi],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt trig_pdacu_foi],
          %i[disclosure_bmt trig_awdis_foi],
          %i[disclosure_bmt trig_responded_foi],
          %i[disclosure_bmt full_unassigned_foi],
          %i[disclosure_bmt full_awresp_foi],
          %i[disclosure_bmt full_draft_foi],
          %i[disclosure_bmt full_ppress_foi],
          %i[disclosure_bmt full_pprivate_foi],
          %i[disclosure_bmt full_awdis_foi],
          %i[disclosure_bmt full_responded_foi],
          %i[disclosure_bmt trig_unassigned_foi_accepted],
          %i[disclosure_bmt trig_awresp_foi_accepted],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt trig_pdacu_foi_accepted],
          %i[disclosure_bmt full_awresp_foi_accepted],
          %i[disclosure_bmt full_pdacu_foi_accepted],
          %i[disclosure_bmt full_pdacu_foi_unaccepted],
          %i[disclosure_bmt std_closed_foi],
          %i[disclosure_bmt trig_closed_foi],
          %i[disclosure_bmt full_closed_foi],
          %i[disclosure_specialist std_unassigned_foi],
          %i[disclosure_specialist std_awresp_foi],
          %i[disclosure_specialist std_draft_foi],
          %i[disclosure_specialist std_draft_foi_in_escalation_period],
          %i[disclosure_specialist std_awdis_foi],
          %i[disclosure_specialist std_responded_foi],
          %i[disclosure_specialist std_closed_foi],
          %i[disclosure_specialist trig_unassigned_foi],
          %i[disclosure_specialist trig_unassigned_foi_accepted],
          %i[disclosure_specialist trig_awresp_foi],
          %i[disclosure_specialist trig_awresp_foi_accepted],
          %i[disclosure_specialist trig_draft_foi],
          %i[disclosure_specialist trig_draft_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
          %i[disclosure_specialist trig_awdis_foi],
          %i[disclosure_specialist trig_responded_foi],
          %i[disclosure_specialist trig_closed_foi],
          %i[disclosure_specialist full_unassigned_foi],
          %i[disclosure_specialist full_awresp_foi],
          %i[disclosure_specialist full_awresp_foi_accepted],
          %i[disclosure_specialist full_draft_foi],
          %i[disclosure_specialist full_pdacu_foi_accepted],
          %i[disclosure_specialist full_pdacu_foi_unaccepted],
          %i[disclosure_specialist full_ppress_foi],
          %i[disclosure_specialist full_pprivate_foi],
          %i[disclosure_specialist full_awdis_foi],
          %i[disclosure_specialist full_responded_foi],
          %i[disclosure_specialist full_closed_foi],
          %i[disclosure_specialist_coworker std_unassigned_foi],
          %i[disclosure_specialist_coworker std_awresp_foi],
          %i[disclosure_specialist_coworker std_draft_foi],
          %i[disclosure_specialist_coworker std_draft_foi_in_escalation_period],
          %i[disclosure_specialist_coworker std_awdis_foi],
          %i[disclosure_specialist_coworker std_responded_foi],
          %i[disclosure_specialist_coworker std_closed_foi],
          %i[disclosure_specialist_coworker trig_unassigned_foi],
          %i[disclosure_specialist_coworker trig_unassigned_foi_accepted],
          %i[disclosure_specialist_coworker trig_awresp_foi],
          %i[disclosure_specialist_coworker trig_awresp_foi_accepted],
          %i[disclosure_specialist_coworker trig_draft_foi],
          %i[disclosure_specialist_coworker trig_draft_foi_accepted],
          %i[disclosure_specialist_coworker trig_pdacu_foi],
          %i[disclosure_specialist_coworker trig_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker trig_awdis_foi],
          %i[disclosure_specialist_coworker trig_responded_foi],
          %i[disclosure_specialist_coworker trig_closed_foi],
          %i[disclosure_specialist_coworker full_unassigned_foi],
          %i[disclosure_specialist_coworker full_awresp_foi],
          %i[disclosure_specialist_coworker full_awresp_foi_accepted],
          %i[disclosure_specialist_coworker full_draft_foi],
          %i[disclosure_specialist_coworker full_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker full_pdacu_foi_unaccepted],
          %i[disclosure_specialist_coworker full_ppress_foi],
          %i[disclosure_specialist_coworker full_pprivate_foi],
          %i[disclosure_specialist_coworker full_awdis_foi],
          %i[disclosure_specialist_coworker full_responded_foi],
          %i[disclosure_specialist_coworker full_closed_foi],
          %i[another_disclosure_specialist std_unassigned_foi],
          %i[another_disclosure_specialist std_awresp_foi],
          %i[another_disclosure_specialist std_draft_foi],
          %i[another_disclosure_specialist std_draft_foi_in_escalation_period],
          %i[another_disclosure_specialist std_awdis_foi],
          %i[another_disclosure_specialist std_responded_foi],
          %i[another_disclosure_specialist std_closed_foi],
          %i[another_disclosure_specialist trig_unassigned_foi],
          %i[another_disclosure_specialist trig_unassigned_foi_accepted],
          %i[another_disclosure_specialist trig_awresp_foi],
          %i[another_disclosure_specialist trig_awresp_foi_accepted],
          %i[another_disclosure_specialist trig_draft_foi],
          %i[another_disclosure_specialist trig_draft_foi_accepted],
          %i[another_disclosure_specialist trig_pdacu_foi],
          %i[another_disclosure_specialist trig_pdacu_foi_accepted],
          %i[another_disclosure_specialist trig_awdis_foi],
          %i[another_disclosure_specialist trig_responded_foi],
          %i[another_disclosure_specialist trig_closed_foi],
          %i[another_disclosure_specialist full_unassigned_foi],
          %i[another_disclosure_specialist full_awresp_foi],
          %i[another_disclosure_specialist full_awresp_foi_accepted],
          %i[another_disclosure_specialist full_draft_foi],
          %i[another_disclosure_specialist full_pdacu_foi_accepted],
          %i[another_disclosure_specialist full_pdacu_foi_unaccepted],
          %i[another_disclosure_specialist full_ppress_foi],
          %i[another_disclosure_specialist full_pprivate_foi],
          %i[another_disclosure_specialist full_awdis_foi],
          %i[another_disclosure_specialist full_responded_foi],
          %i[another_disclosure_specialist full_closed_foi],
          %i[responder std_unassigned_foi],
          %i[responder std_awresp_foi],
          %i[responder std_draft_foi],
          %i[responder std_draft_foi_in_escalation_period],
          %i[responder std_awdis_foi],
          %i[responder std_responded_foi],
          %i[responder std_closed_foi],
          %i[responder trig_unassigned_foi],
          %i[responder trig_unassigned_foi_accepted],
          %i[responder trig_awresp_foi],
          %i[responder trig_awresp_foi_accepted],
          %i[responder trig_draft_foi],
          %i[responder trig_draft_foi_accepted],
          %i[responder trig_pdacu_foi],
          %i[responder trig_pdacu_foi_accepted],
          %i[responder trig_awdis_foi],
          %i[responder trig_responded_foi],
          %i[responder trig_closed_foi],
          %i[responder full_unassigned_foi],
          %i[responder full_awresp_foi],
          %i[responder full_awresp_foi_accepted],
          %i[responder full_draft_foi],
          %i[responder full_pdacu_foi_accepted],
          %i[responder full_pdacu_foi_unaccepted],
          %i[responder full_ppress_foi],
          %i[responder full_pprivate_foi],
          %i[responder full_awdis_foi],
          %i[responder full_responded_foi],
          %i[responder full_closed_foi],
          %i[sar_responder std_unassigned_foi],
          %i[sar_responder std_awresp_foi],
          %i[sar_responder std_draft_foi],
          %i[sar_responder std_draft_foi_in_escalation_period],
          %i[sar_responder std_awdis_foi],
          %i[sar_responder std_responded_foi],
          %i[sar_responder std_closed_foi],
          %i[sar_responder trig_unassigned_foi],
          %i[sar_responder trig_unassigned_foi_accepted],
          %i[sar_responder trig_awresp_foi],
          %i[sar_responder trig_awresp_foi_accepted],
          %i[sar_responder trig_draft_foi],
          %i[sar_responder trig_draft_foi_accepted],
          %i[sar_responder trig_pdacu_foi],
          %i[sar_responder trig_pdacu_foi_accepted],
          %i[sar_responder trig_awdis_foi],
          %i[sar_responder trig_responded_foi],
          %i[sar_responder trig_closed_foi],
          %i[sar_responder full_unassigned_foi],
          %i[sar_responder full_awresp_foi],
          %i[sar_responder full_awresp_foi_accepted],
          %i[sar_responder full_draft_foi],
          %i[sar_responder full_pdacu_foi_accepted],
          %i[sar_responder full_pdacu_foi_unaccepted],
          %i[sar_responder full_ppress_foi],
          %i[sar_responder full_pprivate_foi],
          %i[sar_responder full_awdis_foi],
          %i[sar_responder full_responded_foi],
          %i[sar_responder full_closed_foi],
          %i[another_responder_in_same_team std_unassigned_foi],
          %i[another_responder_in_same_team std_awresp_foi],
          %i[another_responder_in_same_team std_draft_foi],
          %i[another_responder_in_same_team std_draft_foi_in_escalation_period],
          %i[another_responder_in_same_team std_awdis_foi],
          %i[another_responder_in_same_team std_responded_foi],
          %i[another_responder_in_same_team std_closed_foi],
          %i[another_responder_in_same_team trig_unassigned_foi],
          %i[another_responder_in_same_team trig_unassigned_foi_accepted],
          %i[another_responder_in_same_team trig_awresp_foi],
          %i[another_responder_in_same_team trig_awresp_foi_accepted],
          %i[another_responder_in_same_team trig_draft_foi],
          %i[another_responder_in_same_team trig_draft_foi_accepted],
          %i[another_responder_in_same_team trig_pdacu_foi],
          %i[another_responder_in_same_team trig_pdacu_foi_accepted],
          %i[another_responder_in_same_team trig_awdis_foi],
          %i[another_responder_in_same_team trig_responded_foi],
          %i[another_responder_in_same_team trig_closed_foi],
          %i[another_responder_in_same_team full_unassigned_foi],
          %i[another_responder_in_same_team full_awresp_foi],
          %i[another_responder_in_same_team full_awresp_foi_accepted],
          %i[another_responder_in_same_team full_draft_foi],
          %i[another_responder_in_same_team full_pdacu_foi_accepted],
          %i[another_responder_in_same_team full_pdacu_foi_unaccepted],
          %i[another_responder_in_same_team full_ppress_foi],
          %i[another_responder_in_same_team full_pprivate_foi],
          %i[another_responder_in_same_team full_awdis_foi],
          %i[another_responder_in_same_team full_responded_foi],
          %i[another_responder_in_same_team full_closed_foi],
          %i[another_sar_responder_in_same_team std_unassigned_foi],
          %i[another_sar_responder_in_same_team std_awresp_foi],
          %i[another_sar_responder_in_same_team std_draft_foi],
          %i[another_sar_responder_in_same_team std_draft_foi_in_escalation_period],
          %i[another_sar_responder_in_same_team std_awdis_foi],
          %i[another_sar_responder_in_same_team std_responded_foi],
          %i[another_sar_responder_in_same_team std_closed_foi],
          %i[another_sar_responder_in_same_team trig_unassigned_foi],
          %i[another_sar_responder_in_same_team trig_unassigned_foi_accepted],
          %i[another_sar_responder_in_same_team trig_awresp_foi],
          %i[another_sar_responder_in_same_team trig_awresp_foi_accepted],
          %i[another_sar_responder_in_same_team trig_draft_foi],
          %i[another_sar_responder_in_same_team trig_draft_foi_accepted],
          %i[another_sar_responder_in_same_team trig_pdacu_foi],
          %i[another_sar_responder_in_same_team trig_pdacu_foi_accepted],
          %i[another_sar_responder_in_same_team trig_awdis_foi],
          %i[another_sar_responder_in_same_team trig_responded_foi],
          %i[another_sar_responder_in_same_team trig_closed_foi],
          %i[another_sar_responder_in_same_team full_unassigned_foi],
          %i[another_sar_responder_in_same_team full_awresp_foi],
          %i[another_sar_responder_in_same_team full_awresp_foi_accepted],
          %i[another_sar_responder_in_same_team full_draft_foi],
          %i[another_sar_responder_in_same_team full_pdacu_foi_accepted],
          %i[another_sar_responder_in_same_team full_pdacu_foi_unaccepted],
          %i[another_sar_responder_in_same_team full_ppress_foi],
          %i[another_sar_responder_in_same_team full_pprivate_foi],
          %i[another_sar_responder_in_same_team full_awdis_foi],
          %i[another_sar_responder_in_same_team full_responded_foi],
          %i[another_sar_responder_in_same_team full_closed_foi],
          %i[another_responder_in_diff_team std_unassigned_foi],
          %i[another_responder_in_diff_team std_awresp_foi],
          %i[another_responder_in_diff_team std_draft_foi],
          %i[another_responder_in_diff_team std_draft_foi_in_escalation_period],
          %i[another_responder_in_diff_team std_awdis_foi],
          %i[another_responder_in_diff_team std_responded_foi],
          %i[another_responder_in_diff_team std_closed_foi],
          %i[another_responder_in_diff_team trig_unassigned_foi],
          %i[another_responder_in_diff_team trig_unassigned_foi_accepted],
          %i[another_responder_in_diff_team trig_awresp_foi],
          %i[another_responder_in_diff_team trig_awresp_foi_accepted],
          %i[another_responder_in_diff_team trig_draft_foi],
          %i[another_responder_in_diff_team trig_draft_foi_accepted],
          %i[another_responder_in_diff_team trig_pdacu_foi],
          %i[another_responder_in_diff_team trig_pdacu_foi_accepted],
          %i[another_responder_in_diff_team trig_awdis_foi],
          %i[another_responder_in_diff_team trig_responded_foi],
          %i[another_responder_in_diff_team trig_closed_foi],
          %i[another_responder_in_diff_team full_unassigned_foi],
          %i[another_responder_in_diff_team full_awresp_foi],
          %i[another_responder_in_diff_team full_awresp_foi_accepted],
          %i[another_responder_in_diff_team full_draft_foi],
          %i[another_responder_in_diff_team full_pdacu_foi_accepted],
          %i[another_responder_in_diff_team full_pdacu_foi_unaccepted],
          %i[another_responder_in_diff_team full_ppress_foi],
          %i[another_responder_in_diff_team full_pprivate_foi],
          %i[another_responder_in_diff_team full_awdis_foi],
          %i[another_responder_in_diff_team full_responded_foi],
          %i[another_responder_in_diff_team full_closed_foi],
          %i[another_sar_responder_in_diff_team std_unassigned_foi],
          %i[another_sar_responder_in_diff_team std_awresp_foi],
          %i[another_sar_responder_in_diff_team std_draft_foi],
          %i[another_sar_responder_in_diff_team std_draft_foi_in_escalation_period],
          %i[another_sar_responder_in_diff_team std_awdis_foi],
          %i[another_sar_responder_in_diff_team std_responded_foi],
          %i[another_sar_responder_in_diff_team std_closed_foi],
          %i[another_sar_responder_in_diff_team trig_unassigned_foi],
          %i[another_sar_responder_in_diff_team trig_unassigned_foi_accepted],
          %i[another_sar_responder_in_diff_team trig_awresp_foi],
          %i[another_sar_responder_in_diff_team trig_awresp_foi_accepted],
          %i[another_sar_responder_in_diff_team trig_draft_foi],
          %i[another_sar_responder_in_diff_team trig_draft_foi_accepted],
          %i[another_sar_responder_in_diff_team trig_pdacu_foi],
          %i[another_sar_responder_in_diff_team trig_pdacu_foi_accepted],
          %i[another_sar_responder_in_diff_team trig_awdis_foi],
          %i[another_sar_responder_in_diff_team trig_responded_foi],
          %i[another_sar_responder_in_diff_team trig_closed_foi],
          %i[another_sar_responder_in_diff_team full_unassigned_foi],
          %i[another_sar_responder_in_diff_team full_awresp_foi],
          %i[another_sar_responder_in_diff_team full_awresp_foi_accepted],
          %i[another_sar_responder_in_diff_team full_draft_foi],
          %i[another_sar_responder_in_diff_team full_pdacu_foi_accepted],
          %i[another_sar_responder_in_diff_team full_pdacu_foi_unaccepted],
          %i[another_sar_responder_in_diff_team full_ppress_foi],
          %i[another_sar_responder_in_diff_team full_pprivate_foi],
          %i[another_sar_responder_in_diff_team full_awdis_foi],
          %i[another_sar_responder_in_diff_team full_responded_foi],
          %i[another_sar_responder_in_diff_team full_closed_foi],
          %i[press_officer std_unassigned_foi],
          %i[press_officer std_awresp_foi],
          %i[press_officer std_draft_foi],
          %i[press_officer std_draft_foi_in_escalation_period],
          %i[press_officer std_awdis_foi],
          %i[press_officer std_responded_foi],
          %i[press_officer std_closed_foi],
          %i[press_officer trig_unassigned_foi],
          %i[press_officer trig_unassigned_foi_accepted],
          %i[press_officer trig_awresp_foi],
          %i[press_officer trig_awresp_foi_accepted],
          %i[press_officer trig_draft_foi],
          %i[press_officer trig_draft_foi_accepted],
          %i[press_officer trig_pdacu_foi],
          %i[press_officer trig_pdacu_foi_accepted],
          %i[press_officer trig_awdis_foi],
          %i[press_officer trig_responded_foi],
          %i[press_officer trig_closed_foi],
          %i[press_officer full_unassigned_foi],
          %i[press_officer full_awresp_foi],
          %i[press_officer full_awresp_foi_accepted],
          %i[press_officer full_draft_foi],
          %i[press_officer full_pdacu_foi_accepted],
          %i[press_officer full_pdacu_foi_unaccepted],
          %i[press_officer full_ppress_foi],
          %i[press_officer full_pprivate_foi],
          %i[press_officer full_awdis_foi],
          %i[press_officer full_responded_foi],
          %i[press_officer full_closed_foi],
          %i[private_officer std_unassigned_foi],
          %i[private_officer std_awresp_foi],
          %i[private_officer std_draft_foi],
          %i[private_officer std_draft_foi_in_escalation_period],
          %i[private_officer std_awdis_foi],
          %i[private_officer std_responded_foi],
          %i[private_officer std_closed_foi],
          %i[private_officer trig_unassigned_foi],
          %i[private_officer trig_unassigned_foi_accepted],
          %i[private_officer trig_awresp_foi],
          %i[private_officer trig_awresp_foi_accepted],
          %i[private_officer trig_draft_foi],
          %i[private_officer trig_draft_foi_accepted],
          %i[private_officer trig_pdacu_foi],
          %i[private_officer trig_pdacu_foi_accepted],
          %i[private_officer trig_awdis_foi],
          %i[private_officer trig_responded_foi],
          %i[private_officer trig_closed_foi],
          %i[private_officer full_unassigned_foi],
          %i[private_officer full_awresp_foi],
          %i[private_officer full_awresp_foi_accepted],
          %i[private_officer full_draft_foi],
          %i[private_officer full_pdacu_foi_accepted],
          %i[private_officer full_pdacu_foi_unaccepted],
          %i[private_officer full_ppress_foi],
          %i[private_officer full_pprivate_foi],
          %i[private_officer full_awdis_foi],
          %i[private_officer full_responded_foi],
          %i[private_officer full_closed_foi],
        )
      }
    end

    describe "reassign_user" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist trig_unassigned_foi_accepted],
          %i[disclosure_specialist trig_awresp_foi],
          %i[disclosure_specialist trig_awresp_foi_accepted],
          %i[disclosure_specialist trig_draft_foi],
          %i[disclosure_specialist trig_draft_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
          %i[disclosure_specialist trig_awdis_foi],
          %i[disclosure_specialist full_awresp_foi],
          %i[disclosure_specialist full_awresp_foi_accepted],
          %i[disclosure_specialist full_draft_foi],
          %i[disclosure_specialist full_pdacu_foi_accepted],
          %i[disclosure_specialist full_pdacu_foi_unaccepted],
          %i[disclosure_specialist full_ppress_foi],
          %i[disclosure_specialist full_pprivate_foi],
          %i[disclosure_specialist full_awdis_foi],
          %i[disclosure_specialist_coworker trig_unassigned_foi_accepted],
          %i[disclosure_specialist_coworker trig_awresp_foi],
          %i[disclosure_specialist_coworker trig_awresp_foi_accepted],
          %i[disclosure_specialist_coworker trig_draft_foi],
          %i[disclosure_specialist_coworker trig_draft_foi_accepted],
          %i[disclosure_specialist_coworker trig_pdacu_foi],
          %i[disclosure_specialist_coworker trig_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker trig_awdis_foi],
          %i[disclosure_specialist_coworker full_awresp_foi],
          %i[disclosure_specialist_coworker full_awresp_foi_accepted],
          %i[disclosure_specialist_coworker full_draft_foi],
          %i[disclosure_specialist_coworker full_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker full_pdacu_foi_unaccepted],
          %i[disclosure_specialist_coworker full_ppress_foi],
          %i[disclosure_specialist_coworker full_pprivate_foi],
          %i[disclosure_specialist_coworker full_awdis_foi],
          %i[another_disclosure_specialist trig_awresp_foi],
          %i[another_disclosure_specialist trig_awresp_foi_accepted],
          %i[another_disclosure_specialist trig_draft_foi],
          %i[another_disclosure_specialist trig_draft_foi_accepted],
          %i[another_disclosure_specialist trig_pdacu_foi],
          %i[another_disclosure_specialist trig_pdacu_foi_accepted],
          %i[another_disclosure_specialist full_awresp_foi],
          %i[another_disclosure_specialist full_awresp_foi_accepted],
          %i[another_disclosure_specialist full_draft_foi],
          %i[another_disclosure_specialist full_pdacu_foi_accepted],
          %i[another_disclosure_specialist full_pdacu_foi_unaccepted],
          %i[responder std_draft_foi],
          %i[responder std_draft_foi_in_escalation_period],
          %i[responder std_awdis_foi],
          %i[responder trig_draft_foi],
          %i[responder trig_draft_foi_accepted],
          %i[responder trig_pdacu_foi],
          %i[responder trig_pdacu_foi_accepted],
          %i[responder trig_awdis_foi],
          %i[responder full_draft_foi],
          %i[responder full_pdacu_foi_accepted],
          %i[responder full_pdacu_foi_unaccepted],
          %i[responder full_ppress_foi],
          %i[responder full_pprivate_foi],
          %i[responder full_awdis_foi],
          %i[another_responder_in_same_team std_draft_foi],
          %i[another_responder_in_same_team std_draft_foi_in_escalation_period],
          %i[another_responder_in_same_team std_awdis_foi],
          %i[another_responder_in_same_team trig_draft_foi],
          %i[another_responder_in_same_team trig_draft_foi_accepted],
          %i[another_responder_in_same_team trig_pdacu_foi],
          %i[another_responder_in_same_team trig_pdacu_foi_accepted],
          %i[another_responder_in_same_team trig_awdis_foi],
          %i[another_responder_in_same_team full_draft_foi],
          %i[another_responder_in_same_team full_pdacu_foi_accepted],
          %i[another_responder_in_same_team full_pdacu_foi_unaccepted],
          %i[another_responder_in_same_team full_ppress_foi],
          %i[another_responder_in_same_team full_pprivate_foi],
          %i[another_responder_in_same_team full_awdis_foi],
          %i[press_officer trig_awresp_foi],
          %i[press_officer trig_awresp_foi_accepted],
          %i[press_officer trig_draft_foi],
          %i[press_officer trig_draft_foi_accepted],
          %i[press_officer trig_pdacu_foi],
          %i[press_officer trig_pdacu_foi_accepted],
          %i[press_officer full_unassigned_foi],
          %i[press_officer full_awresp_foi],
          %i[press_officer full_awresp_foi_accepted],
          %i[press_officer full_draft_foi],
          %i[press_officer full_pdacu_foi_accepted],
          %i[press_officer full_pdacu_foi_unaccepted],
          %i[press_officer full_ppress_foi],
          %i[press_officer full_pprivate_foi],
          %i[press_officer full_awdis_foi],
          %i[private_officer trig_awresp_foi],
          %i[private_officer trig_awresp_foi_accepted],
          %i[private_officer trig_draft_foi],
          %i[private_officer trig_draft_foi_accepted],
          %i[private_officer trig_pdacu_foi],
          %i[private_officer trig_pdacu_foi_accepted],
          %i[private_officer full_unassigned_foi],
          %i[private_officer full_awresp_foi],
          %i[private_officer full_awresp_foi_accepted],
          %i[private_officer full_draft_foi],
          %i[private_officer full_pdacu_foi_accepted],
          %i[private_officer full_pdacu_foi_unaccepted],
          %i[private_officer full_ppress_foi],
          %i[private_officer full_pprivate_foi],
          %i[private_officer full_awdis_foi],
        )
      }
    end

    describe "reject_responder_assignment" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[responder std_awresp_foi],
          %i[responder trig_awresp_foi],
          %i[responder trig_awresp_foi_accepted],
          %i[responder full_awresp_foi],
          %i[responder full_awresp_foi_accepted],
          %i[another_responder_in_same_team std_awresp_foi],
          %i[another_responder_in_same_team trig_awresp_foi_accepted],
          %i[another_responder_in_same_team trig_awresp_foi],
          %i[another_responder_in_same_team full_awresp_foi],
          %i[another_responder_in_same_team full_awresp_foi_accepted],
        )
      }
    end

    describe "remove_linked_case" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_unassigned_foi],
          %i[disclosure_bmt std_awresp_foi],
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt std_awdis_foi],
          %i[disclosure_bmt std_responded_foi],
          %i[disclosure_bmt trig_unassigned_foi],
          %i[disclosure_bmt trig_awresp_foi],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt trig_pdacu_foi],
          %i[disclosure_bmt trig_pdacu_foi_accepted],
          %i[disclosure_bmt trig_awdis_foi],
          %i[disclosure_bmt trig_responded_foi],
          %i[disclosure_bmt full_unassigned_foi],
          %i[disclosure_bmt full_awresp_foi],
          %i[disclosure_bmt full_draft_foi],
          %i[disclosure_bmt full_ppress_foi],
          %i[disclosure_bmt full_pprivate_foi],
          %i[disclosure_bmt full_awdis_foi],
          %i[disclosure_bmt full_responded_foi],
          %i[disclosure_bmt trig_unassigned_foi_accepted],
          %i[disclosure_bmt trig_awresp_foi_accepted],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt full_awresp_foi_accepted],
          %i[disclosure_bmt full_pdacu_foi_accepted],
          %i[disclosure_bmt full_pdacu_foi_unaccepted],
          %i[disclosure_bmt std_closed_foi],
          %i[disclosure_bmt trig_closed_foi],
          %i[disclosure_bmt full_closed_foi],
          %i[disclosure_specialist std_unassigned_foi],
          %i[disclosure_specialist std_awresp_foi],
          %i[disclosure_specialist std_draft_foi],
          %i[disclosure_specialist std_draft_foi_in_escalation_period],
          %i[disclosure_specialist std_awdis_foi],
          %i[disclosure_specialist std_responded_foi],
          %i[disclosure_specialist std_closed_foi],
          %i[disclosure_specialist trig_unassigned_foi],
          %i[disclosure_specialist trig_unassigned_foi_accepted],
          %i[disclosure_specialist trig_awresp_foi],
          %i[disclosure_specialist trig_awresp_foi_accepted],
          %i[disclosure_specialist trig_draft_foi],
          %i[disclosure_specialist trig_draft_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
          %i[disclosure_specialist trig_awdis_foi],
          %i[disclosure_specialist trig_responded_foi],
          %i[disclosure_specialist trig_closed_foi],
          %i[disclosure_specialist full_unassigned_foi],
          %i[disclosure_specialist full_awresp_foi],
          %i[disclosure_specialist full_awresp_foi_accepted],
          %i[disclosure_specialist full_draft_foi],
          %i[disclosure_specialist full_pdacu_foi_accepted],
          %i[disclosure_specialist full_pdacu_foi_unaccepted],
          %i[disclosure_specialist full_ppress_foi],
          %i[disclosure_specialist full_pprivate_foi],
          %i[disclosure_specialist full_awdis_foi],
          %i[disclosure_specialist full_responded_foi],
          %i[disclosure_specialist full_closed_foi],
          %i[another_disclosure_specialist std_unassigned_foi],
          %i[another_disclosure_specialist std_awresp_foi],
          %i[another_disclosure_specialist std_draft_foi],
          %i[another_disclosure_specialist std_draft_foi_in_escalation_period],
          %i[another_disclosure_specialist std_awdis_foi],
          %i[another_disclosure_specialist std_responded_foi],
          %i[another_disclosure_specialist std_closed_foi],
          %i[another_disclosure_specialist trig_unassigned_foi],
          %i[another_disclosure_specialist trig_unassigned_foi_accepted],
          %i[another_disclosure_specialist trig_awresp_foi],
          %i[another_disclosure_specialist trig_awresp_foi_accepted],
          %i[another_disclosure_specialist trig_draft_foi],
          %i[another_disclosure_specialist trig_draft_foi_accepted],
          %i[another_disclosure_specialist trig_pdacu_foi],
          %i[another_disclosure_specialist trig_pdacu_foi_accepted],
          %i[another_disclosure_specialist trig_awdis_foi],
          %i[another_disclosure_specialist trig_responded_foi],
          %i[another_disclosure_specialist trig_closed_foi],
          %i[another_disclosure_specialist full_unassigned_foi],
          %i[another_disclosure_specialist full_awresp_foi],
          %i[another_disclosure_specialist full_awresp_foi_accepted],
          %i[another_disclosure_specialist full_draft_foi],
          %i[another_disclosure_specialist full_pdacu_foi_accepted],
          %i[another_disclosure_specialist full_pdacu_foi_unaccepted],
          %i[another_disclosure_specialist full_ppress_foi],
          %i[another_disclosure_specialist full_pprivate_foi],
          %i[another_disclosure_specialist full_awdis_foi],
          %i[another_disclosure_specialist full_responded_foi],
          %i[another_disclosure_specialist full_closed_foi],
          %i[disclosure_specialist_coworker std_unassigned_foi],
          %i[disclosure_specialist_coworker std_awresp_foi],
          %i[disclosure_specialist_coworker std_draft_foi],
          %i[disclosure_specialist_coworker std_draft_foi_in_escalation_period],
          %i[disclosure_specialist_coworker std_awdis_foi],
          %i[disclosure_specialist_coworker std_responded_foi],
          %i[disclosure_specialist_coworker std_closed_foi],
          %i[disclosure_specialist_coworker trig_unassigned_foi],
          %i[disclosure_specialist_coworker trig_unassigned_foi_accepted],
          %i[disclosure_specialist_coworker trig_awresp_foi],
          %i[disclosure_specialist_coworker trig_awresp_foi_accepted],
          %i[disclosure_specialist_coworker trig_draft_foi],
          %i[disclosure_specialist_coworker trig_draft_foi_accepted],
          %i[disclosure_specialist_coworker trig_pdacu_foi],
          %i[disclosure_specialist_coworker trig_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker trig_awdis_foi],
          %i[disclosure_specialist_coworker trig_responded_foi],
          %i[disclosure_specialist_coworker trig_closed_foi],
          %i[disclosure_specialist_coworker full_unassigned_foi],
          %i[disclosure_specialist_coworker full_awresp_foi],
          %i[disclosure_specialist_coworker full_awresp_foi_accepted],
          %i[disclosure_specialist_coworker full_draft_foi],
          %i[disclosure_specialist_coworker full_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker full_pdacu_foi_unaccepted],
          %i[disclosure_specialist_coworker full_ppress_foi],
          %i[disclosure_specialist_coworker full_pprivate_foi],
          %i[disclosure_specialist_coworker full_awdis_foi],
          %i[disclosure_specialist_coworker full_responded_foi],
          %i[disclosure_specialist_coworker full_closed_foi],
          %i[responder std_unassigned_foi],
          %i[responder std_awresp_foi],
          %i[responder std_draft_foi],
          %i[responder std_draft_foi_in_escalation_period],
          %i[responder std_awdis_foi],
          %i[responder std_responded_foi],
          %i[responder std_closed_foi],
          %i[responder trig_unassigned_foi],
          %i[responder trig_unassigned_foi_accepted],
          %i[responder trig_awresp_foi],
          %i[responder trig_awresp_foi_accepted],
          %i[responder trig_draft_foi],
          %i[responder trig_draft_foi_accepted],
          %i[responder trig_pdacu_foi],
          %i[responder trig_pdacu_foi_accepted],
          %i[responder trig_awdis_foi],
          %i[responder trig_responded_foi],
          %i[responder trig_closed_foi],
          %i[responder full_unassigned_foi],
          %i[responder full_awresp_foi],
          %i[responder full_awresp_foi_accepted],
          %i[responder full_draft_foi],
          %i[responder full_pdacu_foi_accepted],
          %i[responder full_pdacu_foi_unaccepted],
          %i[responder full_ppress_foi],
          %i[responder full_pprivate_foi],
          %i[responder full_awdis_foi],
          %i[responder full_responded_foi],
          %i[responder full_closed_foi],
          %i[sar_responder std_unassigned_foi],
          %i[sar_responder std_awresp_foi],
          %i[sar_responder std_draft_foi],
          %i[sar_responder std_draft_foi_in_escalation_period],
          %i[sar_responder std_awdis_foi],
          %i[sar_responder std_responded_foi],
          %i[sar_responder std_closed_foi],
          %i[sar_responder trig_unassigned_foi],
          %i[sar_responder trig_unassigned_foi_accepted],
          %i[sar_responder trig_awresp_foi],
          %i[sar_responder trig_awresp_foi_accepted],
          %i[sar_responder trig_draft_foi],
          %i[sar_responder trig_draft_foi_accepted],
          %i[sar_responder trig_pdacu_foi],
          %i[sar_responder trig_pdacu_foi_accepted],
          %i[sar_responder trig_awdis_foi],
          %i[sar_responder trig_responded_foi],
          %i[sar_responder trig_closed_foi],
          %i[sar_responder full_unassigned_foi],
          %i[sar_responder full_awresp_foi],
          %i[sar_responder full_awresp_foi_accepted],
          %i[sar_responder full_draft_foi],
          %i[sar_responder full_pdacu_foi_accepted],
          %i[sar_responder full_pdacu_foi_unaccepted],
          %i[sar_responder full_ppress_foi],
          %i[sar_responder full_pprivate_foi],
          %i[sar_responder full_awdis_foi],
          %i[sar_responder full_responded_foi],
          %i[sar_responder full_closed_foi],
          %i[another_responder_in_same_team std_unassigned_foi],
          %i[another_responder_in_same_team std_awresp_foi],
          %i[another_responder_in_same_team std_draft_foi],
          %i[another_responder_in_same_team std_draft_foi_in_escalation_period],
          %i[another_responder_in_same_team std_awdis_foi],
          %i[another_responder_in_same_team std_responded_foi],
          %i[another_responder_in_same_team std_closed_foi],
          %i[another_responder_in_same_team trig_unassigned_foi],
          %i[another_responder_in_same_team trig_unassigned_foi_accepted],
          %i[another_responder_in_same_team trig_awresp_foi],
          %i[another_responder_in_same_team trig_awresp_foi_accepted],
          %i[another_responder_in_same_team trig_draft_foi],
          %i[another_responder_in_same_team trig_draft_foi_accepted],
          %i[another_responder_in_same_team trig_pdacu_foi],
          %i[another_responder_in_same_team trig_pdacu_foi_accepted],
          %i[another_responder_in_same_team trig_awdis_foi],
          %i[another_responder_in_same_team trig_responded_foi],
          %i[another_responder_in_same_team trig_closed_foi],
          %i[another_responder_in_same_team full_unassigned_foi],
          %i[another_responder_in_same_team full_awresp_foi],
          %i[another_responder_in_same_team full_awresp_foi_accepted],
          %i[another_responder_in_same_team full_draft_foi],
          %i[another_responder_in_same_team full_pdacu_foi_accepted],
          %i[another_responder_in_same_team full_pdacu_foi_unaccepted],
          %i[another_responder_in_same_team full_ppress_foi],
          %i[another_responder_in_same_team full_pprivate_foi],
          %i[another_responder_in_same_team full_awdis_foi],
          %i[another_responder_in_same_team full_responded_foi],
          %i[another_responder_in_same_team full_closed_foi],
          %i[another_sar_responder_in_same_team std_unassigned_foi],
          %i[another_sar_responder_in_same_team std_awresp_foi],
          %i[another_sar_responder_in_same_team std_draft_foi],
          %i[another_sar_responder_in_same_team std_draft_foi_in_escalation_period],
          %i[another_sar_responder_in_same_team std_awdis_foi],
          %i[another_sar_responder_in_same_team std_responded_foi],
          %i[another_sar_responder_in_same_team std_closed_foi],
          %i[another_sar_responder_in_same_team trig_unassigned_foi],
          %i[another_sar_responder_in_same_team trig_unassigned_foi_accepted],
          %i[another_sar_responder_in_same_team trig_awresp_foi],
          %i[another_sar_responder_in_same_team trig_awresp_foi_accepted],
          %i[another_sar_responder_in_same_team trig_draft_foi],
          %i[another_sar_responder_in_same_team trig_draft_foi_accepted],
          %i[another_sar_responder_in_same_team trig_pdacu_foi],
          %i[another_sar_responder_in_same_team trig_pdacu_foi_accepted],
          %i[another_sar_responder_in_same_team trig_awdis_foi],
          %i[another_sar_responder_in_same_team trig_responded_foi],
          %i[another_sar_responder_in_same_team trig_closed_foi],
          %i[another_sar_responder_in_same_team full_unassigned_foi],
          %i[another_sar_responder_in_same_team full_awresp_foi],
          %i[another_sar_responder_in_same_team full_awresp_foi_accepted],
          %i[another_sar_responder_in_same_team full_draft_foi],
          %i[another_sar_responder_in_same_team full_pdacu_foi_accepted],
          %i[another_sar_responder_in_same_team full_pdacu_foi_unaccepted],
          %i[another_sar_responder_in_same_team full_ppress_foi],
          %i[another_sar_responder_in_same_team full_pprivate_foi],
          %i[another_sar_responder_in_same_team full_awdis_foi],
          %i[another_sar_responder_in_same_team full_responded_foi],
          %i[another_sar_responder_in_same_team full_closed_foi],
          %i[another_responder_in_diff_team std_unassigned_foi],
          %i[another_responder_in_diff_team std_awresp_foi],
          %i[another_responder_in_diff_team std_draft_foi],
          %i[another_responder_in_diff_team std_draft_foi_in_escalation_period],
          %i[another_responder_in_diff_team std_awdis_foi],
          %i[another_responder_in_diff_team std_responded_foi],
          %i[another_responder_in_diff_team std_closed_foi],
          %i[another_responder_in_diff_team trig_unassigned_foi],
          %i[another_responder_in_diff_team trig_unassigned_foi_accepted],
          %i[another_responder_in_diff_team trig_awresp_foi],
          %i[another_responder_in_diff_team trig_awresp_foi_accepted],
          %i[another_responder_in_diff_team trig_draft_foi],
          %i[another_responder_in_diff_team trig_draft_foi_accepted],
          %i[another_responder_in_diff_team trig_pdacu_foi],
          %i[another_responder_in_diff_team trig_pdacu_foi_accepted],
          %i[another_responder_in_diff_team trig_awdis_foi],
          %i[another_responder_in_diff_team trig_responded_foi],
          %i[another_responder_in_diff_team trig_closed_foi],
          %i[another_responder_in_diff_team full_unassigned_foi],
          %i[another_responder_in_diff_team full_awresp_foi],
          %i[another_responder_in_diff_team full_awresp_foi_accepted],
          %i[another_responder_in_diff_team full_draft_foi],
          %i[another_responder_in_diff_team full_pdacu_foi_accepted],
          %i[another_responder_in_diff_team full_pdacu_foi_unaccepted],
          %i[another_responder_in_diff_team full_ppress_foi],
          %i[another_responder_in_diff_team full_pprivate_foi],
          %i[another_responder_in_diff_team full_awdis_foi],
          %i[another_responder_in_diff_team full_responded_foi],
          %i[another_responder_in_diff_team full_closed_foi],
          %i[another_sar_responder_in_diff_team std_unassigned_foi],
          %i[another_sar_responder_in_diff_team std_awresp_foi],
          %i[another_sar_responder_in_diff_team std_draft_foi],
          %i[another_sar_responder_in_diff_team std_draft_foi_in_escalation_period],
          %i[another_sar_responder_in_diff_team std_awdis_foi],
          %i[another_sar_responder_in_diff_team std_responded_foi],
          %i[another_sar_responder_in_diff_team std_closed_foi],
          %i[another_sar_responder_in_diff_team trig_unassigned_foi],
          %i[another_sar_responder_in_diff_team trig_unassigned_foi_accepted],
          %i[another_sar_responder_in_diff_team trig_awresp_foi],
          %i[another_sar_responder_in_diff_team trig_awresp_foi_accepted],
          %i[another_sar_responder_in_diff_team trig_draft_foi],
          %i[another_sar_responder_in_diff_team trig_draft_foi_accepted],
          %i[another_sar_responder_in_diff_team trig_pdacu_foi],
          %i[another_sar_responder_in_diff_team trig_pdacu_foi_accepted],
          %i[another_sar_responder_in_diff_team trig_awdis_foi],
          %i[another_sar_responder_in_diff_team trig_responded_foi],
          %i[another_sar_responder_in_diff_team trig_closed_foi],
          %i[another_sar_responder_in_diff_team full_unassigned_foi],
          %i[another_sar_responder_in_diff_team full_awresp_foi],
          %i[another_sar_responder_in_diff_team full_awresp_foi_accepted],
          %i[another_sar_responder_in_diff_team full_draft_foi],
          %i[another_sar_responder_in_diff_team full_pdacu_foi_accepted],
          %i[another_sar_responder_in_diff_team full_pdacu_foi_unaccepted],
          %i[another_sar_responder_in_diff_team full_ppress_foi],
          %i[another_sar_responder_in_diff_team full_pprivate_foi],
          %i[another_sar_responder_in_diff_team full_awdis_foi],
          %i[another_sar_responder_in_diff_team full_responded_foi],
          %i[another_sar_responder_in_diff_team full_closed_foi],
          %i[press_officer std_unassigned_foi],
          %i[press_officer std_awresp_foi],
          %i[press_officer std_draft_foi],
          %i[press_officer std_draft_foi_in_escalation_period],
          %i[press_officer std_awdis_foi],
          %i[press_officer std_responded_foi],
          %i[press_officer std_closed_foi],
          %i[press_officer trig_unassigned_foi],
          %i[press_officer trig_unassigned_foi_accepted],
          %i[press_officer trig_awresp_foi],
          %i[press_officer trig_awresp_foi_accepted],
          %i[press_officer trig_draft_foi],
          %i[press_officer trig_draft_foi_accepted],
          %i[press_officer trig_pdacu_foi],
          %i[press_officer trig_pdacu_foi_accepted],
          %i[press_officer trig_awdis_foi],
          %i[press_officer trig_responded_foi],
          %i[press_officer trig_closed_foi],
          %i[press_officer full_unassigned_foi],
          %i[press_officer full_awresp_foi],
          %i[press_officer full_awresp_foi_accepted],
          %i[press_officer full_draft_foi],
          %i[press_officer full_pdacu_foi_accepted],
          %i[press_officer full_pdacu_foi_unaccepted],
          %i[press_officer full_ppress_foi],
          %i[press_officer full_pprivate_foi],
          %i[press_officer full_awdis_foi],
          %i[press_officer full_responded_foi],
          %i[press_officer full_closed_foi],
          %i[private_officer std_unassigned_foi],
          %i[private_officer std_awresp_foi],
          %i[private_officer std_draft_foi],
          %i[private_officer std_draft_foi_in_escalation_period],
          %i[private_officer std_awdis_foi],
          %i[private_officer std_responded_foi],
          %i[private_officer std_closed_foi],
          %i[private_officer trig_unassigned_foi],
          %i[private_officer trig_unassigned_foi_accepted],
          %i[private_officer trig_awresp_foi],
          %i[private_officer trig_awresp_foi_accepted],
          %i[private_officer trig_draft_foi],
          %i[private_officer trig_draft_foi_accepted],
          %i[private_officer trig_pdacu_foi],
          %i[private_officer trig_pdacu_foi_accepted],
          %i[private_officer trig_awdis_foi],
          %i[private_officer trig_responded_foi],
          %i[private_officer trig_closed_foi],
          %i[private_officer full_unassigned_foi],
          %i[private_officer full_awresp_foi],
          %i[private_officer full_awresp_foi_accepted],
          %i[private_officer full_draft_foi],
          %i[private_officer full_pdacu_foi_accepted],
          %i[private_officer full_pdacu_foi_unaccepted],
          %i[private_officer full_ppress_foi],
          %i[private_officer full_pprivate_foi],
          %i[private_officer full_awdis_foi],
          %i[private_officer full_responded_foi],
          %i[private_officer full_closed_foi],
        )
      }
    end

    describe "remove_response" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[responder std_draft_foi],
          %i[responder std_draft_foi_in_escalation_period],
          %i[responder std_awdis_foi],
          %i[responder trig_draft_foi],
          %i[responder trig_draft_foi_accepted],
          %i[responder trig_awdis_foi],
          %i[responder full_draft_foi],
          %i[another_responder_in_same_team std_draft_foi],
          %i[another_responder_in_same_team std_draft_foi_in_escalation_period],
          %i[another_responder_in_same_team std_awdis_foi],
          %i[another_responder_in_same_team trig_draft_foi],
          %i[another_responder_in_same_team trig_draft_foi_accepted],
          %i[another_responder_in_same_team trig_awdis_foi],
          %i[another_responder_in_same_team full_draft_foi],
        )
      }
    end

    describe "request_amends" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[press_officer full_ppress_foi],
          %i[private_officer full_pprivate_foi],
        )
      }
    end

    describe "request_further_clearance" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_unassigned_foi],
          %i[disclosure_bmt std_awresp_foi],
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt std_awdis_foi],
          %i[disclosure_bmt trig_unassigned_foi],
          %i[disclosure_bmt trig_awresp_foi],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt trig_pdacu_foi],
          %i[disclosure_bmt trig_awdis_foi],
          %i[disclosure_bmt trig_unassigned_foi_accepted],
          %i[disclosure_bmt trig_awresp_foi_accepted],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt trig_pdacu_foi_accepted],
        )
      }
    end

    describe "respond" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[responder std_awdis_foi],
          %i[responder trig_awdis_foi],
          %i[responder full_awdis_foi],
          %i[another_responder_in_same_team std_awdis_foi],
          %i[another_responder_in_same_team trig_awdis_foi],
          %i[another_responder_in_same_team full_awdis_foi],
        )
      }
    end

    describe "take_on_for_approval" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[press_officer std_unassigned_foi],
          %i[press_officer std_awresp_foi],
          %i[press_officer std_draft_foi],
          %i[press_officer std_draft_foi_in_escalation_period],
          %i[press_officer std_awdis_foi],
          %i[press_officer trig_unassigned_foi],
          %i[press_officer trig_unassigned_foi_accepted],
          %i[press_officer trig_awresp_foi],
          %i[press_officer trig_awresp_foi_accepted],
          %i[press_officer trig_draft_foi],
          %i[press_officer trig_draft_foi_accepted],
          %i[press_officer trig_awdis_foi],
          %i[private_officer std_unassigned_foi],
          %i[private_officer std_awresp_foi],
          %i[private_officer std_draft_foi],
          %i[private_officer std_draft_foi_in_escalation_period],
          %i[private_officer std_awdis_foi],
          %i[private_officer trig_unassigned_foi],
          %i[private_officer trig_unassigned_foi_accepted],
          %i[private_officer trig_awresp_foi],
          %i[private_officer trig_awresp_foi_accepted],
          %i[private_officer trig_draft_foi],
          %i[private_officer trig_draft_foi_accepted],
          %i[private_officer trig_awdis_foi],
          # another approver and approver are permitted here since the policy allows
          # any team that has not taken the case on to take it on
          %i[another_disclosure_specialist std_unassigned_foi],
          %i[another_disclosure_specialist std_awresp_foi],
          %i[another_disclosure_specialist std_draft_foi],
          %i[another_disclosure_specialist std_draft_foi_in_escalation_period],
          %i[another_disclosure_specialist std_awdis_foi],
          %i[another_disclosure_specialist trig_unassigned_foi],
          %i[another_disclosure_specialist trig_unassigned_foi_accepted],
          %i[another_disclosure_specialist trig_awresp_foi],
          %i[another_disclosure_specialist trig_awresp_foi_accepted],
          %i[another_disclosure_specialist trig_draft_foi],
          %i[another_disclosure_specialist trig_draft_foi_accepted],
          %i[another_disclosure_specialist trig_awdis_foi],
          %i[another_disclosure_specialist full_unassigned_foi],
          %i[another_disclosure_specialist full_awresp_foi],
          %i[another_disclosure_specialist full_awresp_foi_accepted],
          %i[another_disclosure_specialist full_draft_foi],
          %i[disclosure_specialist_coworker std_unassigned_foi],
          %i[disclosure_specialist_coworker std_awresp_foi],
          %i[disclosure_specialist_coworker std_draft_foi],
          %i[disclosure_specialist_coworker std_draft_foi_in_escalation_period],
          %i[disclosure_specialist_coworker std_awdis_foi],
          %i[disclosure_specialist std_unassigned_foi],
          %i[disclosure_specialist std_awresp_foi],
          %i[disclosure_specialist std_draft_foi],
          %i[disclosure_specialist std_draft_foi_in_escalation_period],
          %i[disclosure_specialist std_awdis_foi],
        )
      }
    end

    describe "update_closure" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_closed_foi],
          %i[disclosure_bmt trig_closed_foi],
          %i[disclosure_bmt full_closed_foi],
        )
      }
    end

    describe "unaccept_approver_assignment" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist trig_unassigned_foi_accepted],
          %i[disclosure_specialist trig_awresp_foi_accepted],
          %i[disclosure_specialist trig_draft_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
          %i[disclosure_specialist full_awdis_foi],
          %i[press_officer full_awdis_foi],
          %i[private_officer full_awdis_foi],
        )
      }
    end

    describe "unflag_for_clearance" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist trig_unassigned_foi],
          %i[disclosure_specialist trig_unassigned_foi_accepted],
          %i[disclosure_specialist trig_awresp_foi],
          %i[disclosure_specialist trig_awresp_foi_accepted],
          %i[disclosure_specialist trig_draft_foi],
          %i[disclosure_specialist trig_draft_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker trig_unassigned_foi],
          %i[disclosure_specialist_coworker trig_unassigned_foi_accepted],
          %i[disclosure_specialist_coworker trig_awresp_foi],
          %i[disclosure_specialist_coworker trig_awresp_foi_accepted],
          %i[disclosure_specialist_coworker trig_draft_foi],
          %i[disclosure_specialist_coworker trig_draft_foi_accepted],
          %i[disclosure_specialist_coworker trig_pdacu_foi],
          %i[disclosure_specialist_coworker trig_pdacu_foi_accepted],
          %i[press_officer full_unassigned_foi],
          %i[press_officer full_awresp_foi],
          %i[press_officer full_awresp_foi_accepted],
          %i[press_officer full_draft_foi],
          %i[press_officer full_pdacu_foi_accepted],
          %i[press_officer full_pdacu_foi_unaccepted],
          %i[press_officer full_ppress_foi],
          %i[press_officer full_pprivate_foi],
          %i[press_officer full_awdis_foi],
          %i[private_officer full_unassigned_foi],
          %i[private_officer full_awresp_foi],
          %i[private_officer full_awresp_foi_accepted],
          %i[private_officer full_draft_foi],
          %i[private_officer full_pdacu_foi_accepted],
          %i[private_officer full_pdacu_foi_unaccepted],
          %i[private_officer full_ppress_foi],
          %i[private_officer full_pprivate_foi],
          %i[private_officer full_awdis_foi],
        )
      }
    end

    describe "upload_response_and_approve" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist full_pdacu_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
        )
      }
    end

    describe "upload_response_and_return_for_redraft" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist full_pdacu_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
        )
      }
    end

    describe "upload_response_approve_and_bypass" do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_specialist full_pdacu_foi_accepted],
        )
      }
    end

    ############## EMAIL TESTS ################

    describe "add_message_to_case" do
      it {
        expect(subject).to have_after_hook(
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt std_awdis_foi],
          %i[disclosure_bmt std_responded_foi],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt trig_pdacu_foi],
          %i[disclosure_bmt trig_awdis_foi],
          %i[disclosure_bmt trig_responded_foi],
          %i[disclosure_bmt full_draft_foi],
          %i[disclosure_bmt full_ppress_foi],
          %i[disclosure_bmt full_pprivate_foi],
          %i[disclosure_bmt full_awdis_foi],
          %i[disclosure_bmt full_responded_foi],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt trig_pdacu_foi_accepted],
          %i[disclosure_bmt full_pdacu_foi_accepted],
          %i[disclosure_bmt full_pdacu_foi_unaccepted],
          %i[disclosure_specialist trig_draft_foi],
          %i[disclosure_specialist trig_pdacu_foi],
          %i[disclosure_specialist trig_awdis_foi],
          %i[disclosure_specialist trig_responded_foi],
          %i[disclosure_specialist trig_draft_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
          %i[disclosure_specialist full_draft_foi],
          %i[disclosure_specialist full_ppress_foi],
          %i[disclosure_specialist full_pprivate_foi],
          %i[disclosure_specialist full_awdis_foi],
          %i[disclosure_specialist full_responded_foi],
          %i[disclosure_specialist full_pdacu_foi_accepted],
          %i[disclosure_specialist full_pdacu_foi_unaccepted],
          %i[disclosure_specialist_coworker trig_draft_foi],
          %i[disclosure_specialist_coworker trig_pdacu_foi],
          %i[disclosure_specialist_coworker trig_draft_foi_accepted],
          %i[disclosure_specialist_coworker trig_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker full_draft_foi],
          %i[disclosure_specialist_coworker full_ppress_foi],
          %i[disclosure_specialist_coworker full_pprivate_foi],
          %i[disclosure_specialist_coworker full_responded_foi],
          %i[disclosure_specialist_coworker full_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker full_pdacu_foi_unaccepted],
          %i[another_disclosure_specialist trig_draft_foi],
          %i[another_disclosure_specialist trig_draft_foi_accepted],
          %i[another_disclosure_specialist trig_pdacu_foi],
          %i[another_disclosure_specialist trig_pdacu_foi_accepted],
          %i[responder std_draft_foi],
          %i[responder std_draft_foi_in_escalation_period],
          %i[responder std_awdis_foi],
          %i[responder std_responded_foi],
          %i[responder trig_draft_foi],
          %i[responder trig_pdacu_foi],
          %i[responder trig_awdis_foi],
          %i[responder trig_responded_foi],
          %i[responder trig_draft_foi_accepted],
          %i[responder trig_pdacu_foi_accepted],
          %i[responder full_draft_foi],
          %i[responder full_ppress_foi],
          %i[responder full_pprivate_foi],
          %i[responder full_awdis_foi],
          %i[responder full_responded_foi],
          %i[responder full_pdacu_foi_accepted],
          %i[responder full_pdacu_foi_unaccepted],
          %i[another_responder_in_same_team std_draft_foi],
          %i[another_responder_in_same_team std_draft_foi_in_escalation_period],
          %i[another_responder_in_same_team std_awdis_foi],
          %i[another_responder_in_same_team std_responded_foi],
          %i[another_responder_in_same_team trig_draft_foi],
          %i[another_responder_in_same_team trig_draft_foi_accepted],
          %i[another_responder_in_same_team trig_pdacu_foi],
          %i[another_responder_in_same_team trig_pdacu_foi_accepted],
          %i[another_responder_in_same_team trig_awdis_foi],
          %i[another_responder_in_same_team trig_responded_foi],
          %i[another_responder_in_same_team full_draft_foi],
          %i[another_responder_in_same_team full_ppress_foi],
          %i[another_responder_in_same_team full_pprivate_foi],
          %i[another_responder_in_same_team full_awdis_foi],
          %i[another_responder_in_same_team full_responded_foi],
          %i[another_responder_in_same_team full_pdacu_foi_accepted],
          %i[another_responder_in_same_team full_pdacu_foi_unaccepted],
          %i[press_officer trig_draft_foi],
          %i[press_officer trig_pdacu_foi],
          %i[press_officer trig_draft_foi_accepted],
          %i[press_officer trig_pdacu_foi_accepted],
          %i[press_officer full_awdis_foi],
          %i[press_officer full_draft_foi],
          %i[press_officer full_ppress_foi],
          %i[press_officer full_pprivate_foi],
          %i[press_officer full_responded_foi],
          %i[press_officer full_pdacu_foi_accepted],
          %i[press_officer full_pdacu_foi_unaccepted],
          %i[private_officer trig_draft_foi],
          %i[private_officer trig_pdacu_foi],
          %i[private_officer trig_draft_foi_accepted],
          %i[private_officer trig_pdacu_foi_accepted],
          %i[private_officer full_awdis_foi],
          %i[private_officer full_draft_foi],
          %i[private_officer full_ppress_foi],
          %i[private_officer full_pprivate_foi],
          %i[private_officer full_responded_foi],
          %i[private_officer full_pdacu_foi_accepted],
          %i[private_officer full_pdacu_foi_unaccepted],
        ).with_hook("Workflows::Hooks", :notify_responder_message_received)
      }
    end

    describe "upload_response_and_return_for_redraft" do
      it {
        expect(subject).to have_after_hook(
          %i[disclosure_specialist full_pdacu_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
        ).with_hook("Workflows::Hooks", :notify_responder_redraft_requested)
      }
    end

    describe "reassign_user" do
      it {
        expect(subject).to have_after_hook(
          %i[disclosure_specialist trig_unassigned_foi_accepted],
          %i[disclosure_specialist trig_awresp_foi],
          %i[disclosure_specialist trig_awresp_foi_accepted],
          %i[disclosure_specialist trig_draft_foi],
          %i[disclosure_specialist trig_draft_foi_accepted],
          %i[disclosure_specialist trig_pdacu_foi],
          %i[disclosure_specialist trig_pdacu_foi_accepted],
          %i[disclosure_specialist trig_awdis_foi],
          %i[disclosure_specialist full_awresp_foi],
          %i[disclosure_specialist full_awresp_foi_accepted],
          %i[disclosure_specialist full_draft_foi],
          %i[disclosure_specialist full_pdacu_foi_accepted],
          %i[disclosure_specialist full_pdacu_foi_unaccepted],
          %i[disclosure_specialist full_ppress_foi],
          %i[disclosure_specialist full_pprivate_foi],
          %i[disclosure_specialist full_awdis_foi],
          %i[disclosure_specialist_coworker trig_unassigned_foi_accepted],
          %i[disclosure_specialist_coworker trig_awresp_foi],
          %i[disclosure_specialist_coworker trig_awresp_foi_accepted],
          %i[disclosure_specialist_coworker trig_draft_foi],
          %i[disclosure_specialist_coworker trig_draft_foi_accepted],
          %i[disclosure_specialist_coworker trig_pdacu_foi],
          %i[disclosure_specialist_coworker trig_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker trig_awdis_foi],
          %i[disclosure_specialist_coworker full_awresp_foi],
          %i[disclosure_specialist_coworker full_awresp_foi_accepted],
          %i[disclosure_specialist_coworker full_draft_foi],
          %i[disclosure_specialist_coworker full_pdacu_foi_accepted],
          %i[disclosure_specialist_coworker full_pdacu_foi_unaccepted],
          %i[disclosure_specialist_coworker full_ppress_foi],
          %i[disclosure_specialist_coworker full_pprivate_foi],
          %i[disclosure_specialist_coworker full_awdis_foi],
          %i[another_disclosure_specialist trig_awresp_foi],
          %i[another_disclosure_specialist trig_awresp_foi_accepted],
          %i[another_disclosure_specialist trig_draft_foi],
          %i[another_disclosure_specialist trig_draft_foi_accepted],
          %i[another_disclosure_specialist trig_pdacu_foi],
          %i[another_disclosure_specialist trig_pdacu_foi_accepted],
          %i[another_disclosure_specialist full_awresp_foi],
          %i[another_disclosure_specialist full_awresp_foi_accepted],
          %i[another_disclosure_specialist full_draft_foi],
          %i[another_disclosure_specialist full_pdacu_foi_accepted],
          %i[another_disclosure_specialist full_pdacu_foi_unaccepted],
          %i[responder std_draft_foi],
          %i[responder std_draft_foi_in_escalation_period],
          %i[responder std_awdis_foi],
          %i[responder trig_draft_foi],
          %i[responder trig_draft_foi_accepted],
          %i[responder trig_pdacu_foi],
          %i[responder trig_pdacu_foi_accepted],
          %i[responder trig_awdis_foi],
          %i[responder full_draft_foi],
          %i[responder full_pdacu_foi_accepted],
          %i[responder full_pdacu_foi_unaccepted],
          %i[responder full_ppress_foi],
          %i[responder full_pprivate_foi],
          %i[responder full_awdis_foi],
          %i[another_responder_in_same_team std_draft_foi],
          %i[another_responder_in_same_team std_draft_foi_in_escalation_period],
          %i[another_responder_in_same_team std_awdis_foi],
          %i[another_responder_in_same_team trig_draft_foi],
          %i[another_responder_in_same_team trig_draft_foi_accepted],
          %i[another_responder_in_same_team trig_pdacu_foi],
          %i[another_responder_in_same_team trig_pdacu_foi_accepted],
          %i[another_responder_in_same_team trig_awdis_foi],
          %i[another_responder_in_same_team full_draft_foi],
          %i[another_responder_in_same_team full_pdacu_foi_accepted],
          %i[another_responder_in_same_team full_pdacu_foi_unaccepted],
          %i[another_responder_in_same_team full_ppress_foi],
          %i[another_responder_in_same_team full_pprivate_foi],
          %i[another_responder_in_same_team full_awdis_foi],
          %i[press_officer trig_awresp_foi],
          %i[press_officer trig_awresp_foi_accepted],
          %i[press_officer trig_draft_foi],
          %i[press_officer trig_draft_foi_accepted],
          %i[press_officer trig_pdacu_foi],
          %i[press_officer trig_pdacu_foi_accepted],
          %i[press_officer full_awresp_foi],
          %i[press_officer full_awresp_foi_accepted],
          %i[press_officer full_draft_foi],
          %i[press_officer full_pdacu_foi_accepted],
          %i[press_officer full_pdacu_foi_unaccepted],
          %i[press_officer full_ppress_foi],
          %i[press_officer full_pprivate_foi],
          %i[press_officer full_awdis_foi],
          %i[press_officer full_unassigned_foi],
          %i[private_officer trig_awresp_foi],
          %i[private_officer trig_awresp_foi_accepted],
          %i[private_officer trig_draft_foi],
          %i[private_officer trig_draft_foi_accepted],
          %i[private_officer trig_pdacu_foi],
          %i[private_officer trig_pdacu_foi_accepted],
          %i[private_officer full_awresp_foi],
          %i[private_officer full_awresp_foi_accepted],
          %i[private_officer full_draft_foi],
          %i[private_officer full_pdacu_foi_accepted],
          %i[private_officer full_pdacu_foi_unaccepted],
          %i[private_officer full_ppress_foi],
          %i[private_officer full_pprivate_foi],
          %i[private_officer full_awdis_foi],
          %i[private_officer full_unassigned_foi],
        ).with_hook("Workflows::Hooks", :reassign_user_email)
      }
    end

    describe "approve" do
      it {
        expect(subject).to have_after_hook(
          %i[disclosure_specialist trig_pdacu_foi_accepted],
        ).with_hook("Workflows::Hooks", :notify_responder_ready_to_send)
      }
    end

    describe "assign_responder" do
      it {
        expect(subject).to have_after_hook(
          %i[disclosure_bmt std_unassigned_foi],
          %i[disclosure_bmt trig_unassigned_foi],
          %i[disclosure_bmt trig_unassigned_foi_accepted],
          %i[disclosure_bmt full_unassigned_foi],
        ).with_hook("Workflows::Hooks", :assign_responder_email)
      }
    end

    describe "assign_to_new_team" do
      it {
        expect(subject).to have_after_hook(
          %i[disclosure_bmt std_awresp_foi],
          %i[disclosure_bmt std_draft_foi],
          %i[disclosure_bmt std_draft_foi_in_escalation_period],
          %i[disclosure_bmt trig_awresp_foi],
          %i[disclosure_bmt trig_awresp_foi_accepted],
          %i[disclosure_bmt trig_draft_foi],
          %i[disclosure_bmt trig_draft_foi_accepted],
          %i[disclosure_bmt full_awresp_foi],
          %i[disclosure_bmt full_awresp_foi_accepted],
          %i[disclosure_bmt full_draft_foi],
        ).with_hook("Workflows::Hooks", :assign_responder_email)
      }
    end

    describe "upload_response_and_approve" do
      it {
        expect(subject).to have_after_hook(
          %i[disclosure_specialist trig_pdacu_foi_accepted],
        ).with_hook("Workflows::Hooks", :notify_responder_ready_to_send)
      }
    end

    describe "upload_response_approve_and_bypass" do
      it {
        expect(subject).to have_after_hook(
          %i[disclosure_specialist full_pdacu_foi_accepted],
        ).with_hook("Workflows::Hooks", :notify_responder_ready_to_send)
      }
    end
  end

  context "with cases closed the old way" do
    before(:all) do
      DbHousekeeping.clean
      @setup = StandardSetup.new(
        only_cases: %i[
          std_closed_foi
          std_old_closed_foi
          trig_closed_foi
          trig_old_closed_foi
          full_closed_foi
          full_old_closed_foi
        ],
      )
    end

    after(:all) { DbHousekeeping.clean }

    describe :update_closure do
      it {
        expect(subject).to permit_event_to_be_triggered_only_by(
          %i[disclosure_bmt std_closed_foi],
          %i[disclosure_bmt trig_closed_foi],
          %i[disclosure_bmt full_closed_foi],
        )
      }
    end
  end
end
