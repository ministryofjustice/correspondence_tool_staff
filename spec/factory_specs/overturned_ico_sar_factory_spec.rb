require "rails_helper"

describe "Overturned ICO SAR cases factory" do
  let(:frozen_time)             { Time.zone.local(2018, 7, 9, 10, 35, 22) }
  let(:disclosure_bmt)          { find_or_create :team_disclosure_bmt }
  let(:manager)                 { disclosure_bmt.users.first }
  let(:responding_team)         { find_or_create :sar_responding_team }
  let(:responder)               { responding_team.users.first }
  let(:disclosure_team)         { find_or_create :team_disclosure }
  let(:disclosure_specialist)   { disclosure_team.users.first }

  describe "Overturned ICO SAR" do
    context "when standard workflow" do
      describe ":overturned_ico_sar" do
        it "creates an unassigned ICO SAR case" do
          Timecop.freeze(frozen_time) do
            kase = create :overturned_ico_sar
            expect(kase).to be_instance_of(Case::OverturnedICO::SAR)
            expect(kase.workflow).to eq "standard"
            expect(kase.ico_reference_number).to match(/^ICOSARREFNUM\d{3}$/)
            expect(kase.current_state).to eq "unassigned"
            expect(kase.external_deadline).to eq Date.new(2018, 7, 29)
            expect(kase.internal_deadline).to eq Date.new(2018, 6, 29)
            expect(kase.workflow).to eq "standard"
            expect(kase.managing_team).to eq disclosure_bmt
            expect(kase.assignments.size).to eq 1
            expect(kase.received_date).to eq Date.new(2018, 7, 8)

            managing_assignment = kase.assignments.first
            expect(managing_assignment.state).to eq "accepted"
            expect(managing_assignment.team).to eq disclosure_bmt
            expect(managing_assignment.role).to eq "managing"

            expect(kase.transitions.size).to eq 1
          end
        end
      end

      describe ":awaiting_responder_ot_ico_sar" do
        it "creates an assigned ICO SAR case" do
          Timecop.freeze(frozen_time) do
            kase = create(:awaiting_responder_ot_ico_sar, responding_team:)
            expect(kase.workflow).to eq "standard"
            expect(kase.current_state).to eq "awaiting_responder"

            expect(kase.assignments.size).to eq 2
            responding_assignment = kase.assignments.responding.first
            expect(responding_assignment.team).to eq responding_team
            expect(responding_assignment.user).to be_nil
            expect(responding_assignment.state).to eq "pending"

            expect(kase.transitions.size).to eq 2
            transition = kase.transitions.last
            expect(transition.event).to eq "assign_responder"
            expect(transition.acting_team_id).to eq disclosure_bmt.id
            expect(transition.target_team_id).to eq responding_team.id
            expect(transition.target_user_id).to be_nil
            expect(transition.to_workflow).to be_nil
          end
        end
      end

      describe ":accepted_ot_ico_sar" do
        it "creates an case in drafting state" do
          kase = create(:accepted_ot_ico_sar, responding_team:, responder:)
          expect(kase.workflow).to eq "standard"
          expect(kase.current_state).to eq "drafting"
          expect(kase.assignments.size).to eq 2
          responding_assignment = kase.assignments.responding.first
          expect(responding_assignment.team).to eq responding_team
          expect(responding_assignment.user).to eq responder
          expect(responding_assignment.state).to eq "accepted"

          expect(kase.transitions.size).to eq 3
          transition = kase.transitions.last
          expect(transition.event).to eq "accept_responder_assignment"
          expect(transition.acting_team_id).to eq responding_team.id
          expect(transition.acting_user_id).to eq responder.id
          expect(transition.target_team_id).to be_nil
          expect(transition.target_user_id).to be_nil
          expect(transition.to_workflow).to be_nil
        end
      end

      describe ":closed_ot_ico_sar" do
        it "creates a case in responded state" do
          Timecop.freeze(frozen_time) do
            kase = create(:closed_ot_ico_sar,
                          responding_team:,
                          responder:)

            expect(kase).to be_instance_of(Case::OverturnedICO::SAR)
            expect(kase.workflow).to eq "standard"
            expect(kase.current_state).to eq "closed"
            expect(kase.assignments.size).to eq 2

            expect(kase.transitions.size).to eq 5
            transition = kase.transitions.last
            expect(transition.event).to eq "close"
            expect(transition.acting_team_id).to eq responding_team.id
            expect(transition.acting_user_id).to eq responder.id
            expect(transition.target_team_id).to be_nil
            expect(transition.target_user_id).to be_nil
            expect(transition.to_workflow).to be_nil
          end
        end
      end
    end

    context "when trigger workflow" do
      describe ":overturned_ico_sar, :flagged" do
        it "creates an unassigned flagged ICO SAR case" do
          Timecop.freeze(frozen_time) do
            kase = create :overturned_ico_sar,
                          :flagged,
                          :dacu_disclosure,
                          managing_team: disclosure_bmt,
                          manager:,
                          approver: disclosure_specialist

            expect(kase).to be_instance_of(Case::OverturnedICO::SAR)
            expect(kase.workflow).to eq "trigger"
            expect(kase.ico_reference_number).to match(/^ICOSARREFNUM\d{3}$/)
            expect(kase.current_state).to eq "unassigned"
            expect(kase.external_deadline).to eq Date.new(2018, 7, 29)
            expect(kase.internal_deadline).to eq Date.new(2018, 6, 29)
            expect(kase.workflow).to eq "trigger"
            expect(kase.managing_team).to eq disclosure_bmt
            expect(kase.assignments.size).to eq 2

            managing_assignment = kase.assignments.first
            expect(managing_assignment.state).to eq "accepted"
            expect(managing_assignment.team).to eq disclosure_bmt
            expect(managing_assignment.role).to eq "managing"

            approving_assignment = kase.assignments.last
            expect(approving_assignment.state).to eq "pending"
            expect(approving_assignment.team).to eq disclosure_team
            expect(approving_assignment.user).to be_nil
            expect(approving_assignment.role).to eq "approving"
          end
        end
      end

      describe ":overturned_ico_sar, :flagged_accepted, :dacu_disclosure" do
        it "creates an flagged and accepted ICO sar case" do
          Timecop.freeze(frozen_time) do
            kase = create :overturned_ico_sar,
                          :flagged_accepted,
                          :dacu_disclosure,
                          managing_team: disclosure_bmt,
                          manager:,
                          approver: disclosure_specialist

            expect(kase).to be_instance_of(Case::OverturnedICO::SAR)
            expect(kase.workflow).to eq "trigger"
            expect(kase.ico_reference_number).to match(/^ICOSARREFNUM\d{3}$/)
            expect(kase.current_state).to eq "unassigned"
            expect(kase.external_deadline).to eq Date.new(2018, 7, 29)
            expect(kase.internal_deadline).to eq Date.new(2018, 6, 29)
            expect(kase.workflow).to eq "trigger"
            expect(kase.managing_team).to eq disclosure_bmt
            expect(kase.assignments.size).to eq 2

            managing_assignment = kase.assignments.first
            expect(managing_assignment.state).to eq "accepted"
            expect(managing_assignment.team).to eq disclosure_bmt
            expect(managing_assignment.role).to eq "managing"

            approving_assignment = kase.assignments.last
            expect(approving_assignment.state).to eq "accepted"
            expect(approving_assignment.team).to eq disclosure_team
            expect(approving_assignment.user).to eq disclosure_specialist
            expect(approving_assignment.role).to eq "approving"
          end
        end
      end

      describe ":awaiting_responder_ot_ico_sar, :flagged_accepted" do
        it "creates an assigned ICO SAR case" do
          Timecop.freeze(frozen_time) do
            kase = create :awaiting_responder_ot_ico_sar,
                          :flagged_accepted,
                          :dacu_disclosure
            expect(kase.workflow).to eq "trigger"
            expect(kase.current_state).to eq "awaiting_responder"

            expect(kase.assignments.size).to eq 3
            responding_assignment = kase.assignments.responding.first
            expect(responding_assignment.team).to eq responding_team
            expect(responding_assignment.user).to be_nil
            expect(responding_assignment.state).to eq "pending"

            expect(kase.transitions.size).to eq 4
            transition = kase.transitions.second
            expect(transition.event).to eq "assign_responder"
            expect(transition.to_state).to eq "awaiting_responder"
            expect(transition.acting_team_id).to eq disclosure_bmt.id
            expect(transition.target_team_id).to eq responding_team.id
            expect(transition.target_user_id).to be_nil
            expect(transition.to_workflow).to be_nil

            transition = kase.transitions.third
            expect(transition.event).to eq "flag_for_clearance"
            expect(transition.to_state).to eq "awaiting_responder"
            expect(transition.target_team_id).to eq disclosure_team.id
            expect(transition.target_user_id).to be_nil

            transition = kase.transitions.last
            expect(transition.event).to eq "accept_approver_assignment"
            expect(transition.to_state).to eq "awaiting_responder"
            expect(transition.acting_team_id).to eq disclosure_team.id
            expect(transition.acting_user_id).to eq disclosure_specialist.id
          end
        end
      end

      describe ":pending_dacu_clearance_ot_ico_sar" do
        it "creates a pending dacu clearance ot ico sar" do
          kase = create :pending_dacu_clearance_ico_sar_case, :flagged_accepted, :dacu_disclosure
          expect(kase.workflow).to eq "trigger"
          expect(kase.current_state).to eq "pending_dacu_clearance"

          transition = kase.transitions.detect { |t| t.event == "progress_for_clearance" }
          expect(transition.event).to eq "progress_for_clearance"
          expect(transition.to_state).to eq "pending_dacu_clearance"
          expect(transition.acting_team).to eq kase.responding_team
        end
      end

      describe ":awaiting_dispatch_ot_ico_sar, :flagged_accepted, :dacu_disclosure" do
        it "creates a an awaiting  ot ico sar" do
          kase = create :awaiting_dispatch_ot_ico_sar,
                        :flagged_accepted,
                        :dacu_disclosure
          expect(kase.workflow).to eq "trigger"
          expect(kase.current_state).to eq "awaiting_dispatch"

          transition = kase.transitions.detect { |t| t.event == "approve" }
          expect(transition.event).to eq "approve"
          expect(transition.to_state).to eq "awaiting_dispatch"
          expect(transition.acting_user_id).to eq disclosure_specialist.id
          expect(transition.acting_team_id).to eq disclosure_team.id
          expect(transition.target_team_id).to be_nil
          expect(transition.target_user_id).to be_nil
        end
      end
    end
  end
end
