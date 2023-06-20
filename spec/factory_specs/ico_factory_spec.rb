require "rails_helper"

describe "ICO cases factory" do
  let(:frozen_time)             { Time.zone.local(2018, 7, 9, 10, 35, 22) }
  let(:disclosure_bmt)          { find_or_create :team_disclosure_bmt }
  let(:manager)                 { disclosure_bmt.users.first }
  let(:responding_team)         { find_or_create :foi_responding_team }
  let(:responder)               { find_or_create :foi_responder }
  let(:disclosure_team)         { find_or_create :team_disclosure }
  let(:disclosure_specialist)   { disclosure_team.users.first }

  context "when ICO FOI cases" do
    let(:responding_team) { find_or_create :foi_responding_team }

    describe :ico_foi_case do
      it "creates an unassigned ICO FOI case" do
        Timecop.freeze(frozen_time) do
          kase = create :ico_foi_case
          expect(kase).to be_instance_of(Case::ICO::FOI)
          expect(kase.created_at).to eq Time.zone.local(2018, 7, 3, 10, 35, 22)
          expect(kase.ico_reference_number).to match(/^ICOFOIREFNUM\d{3}$/)
          expect(kase.ico_officer_name).to match(/ ico officer name \d+$/)
          expect(kase.current_state).to eq "unassigned"
          expect(kase.external_deadline).to eq Date.new(2018, 8, 6)
          expect(kase.internal_deadline).to eq Date.new(2018, 7, 23)
          expect(kase.workflow).to eq "trigger"
          expect(kase.managing_team).to eq disclosure_bmt
          expect(kase.assignments.size).to eq 2

          managing_assignment = kase.assignments.first
          expect(managing_assignment.state).to eq "accepted"
          expect(managing_assignment.team).to eq disclosure_bmt
          expect(managing_assignment.role).to eq "managing"

          expect(kase.transitions.size).to eq 2
        end
      end
    end

    describe :awaiting_responder_ico_foi_case do
      it "creates an assigned ICO FOI case" do
        Timecop.freeze(frozen_time) do
          kase = create(:awaiting_responder_ico_foi_case, responding_team:)
          expect(kase.current_state).to eq "awaiting_responder"

          expect(kase.assignments.size).to eq 3
          responding_assignment = kase.assignments.responding.first
          expect(responding_assignment.team).to eq responding_team
          expect(responding_assignment.user).to be_nil
          expect(responding_assignment.state).to eq "pending"

          expect(kase.transitions.size).to eq 3
          transition = kase.transitions.last
          expect(transition.event).to eq "assign_responder"
          expect(transition.acting_team_id).to eq disclosure_bmt.id
          expect(transition.target_team_id).to eq responding_team.id
          expect(transition.target_user_id).to be_nil
          expect(transition.to_workflow).to be_nil
        end
      end
    end

    describe :accepted_ico_foi_case do
      it "creates an case in drafting state" do
        kase = create(:accepted_ico_foi_case, responding_team:, responder:)
        expect(kase.current_state).to eq "drafting"
        expect(kase.assignments.size).to eq 3
        responding_assignment = kase.assignments.responding.first
        expect(responding_assignment.team).to eq responding_team
        expect(responding_assignment.user).to eq responder
        expect(responding_assignment.state).to eq "accepted"

        expect(kase.transitions.size).to eq 4
        transition = kase.transitions.last
        expect(transition.event).to eq "accept_responder_assignment"
        expect(transition.acting_team_id).to eq responding_team.id
        expect(transition.acting_user_id).to eq responder.id
        expect(transition.target_team_id).to be_nil
        expect(transition.target_user_id).to be_nil
        expect(transition.to_workflow).to be_nil
      end
    end

    describe :pending_dacu_clearance_ico_foi_case do
      it "creates a pending_dacu_clearance_case" do
        kase = create :pending_dacu_clearance_ico_foi_case,
                      responding_team:,
                      responder:,
                      approver: disclosure_specialist

        expect(kase.current_state).to eq "pending_dacu_clearance"
        expect(kase.assignments.size).to eq 3
        approving_assignment = kase.assignments.approving.first
        expect(approving_assignment.team).to eq disclosure_team
        expect(approving_assignment.user).to eq disclosure_specialist
        expect(approving_assignment.state).to eq "accepted"

        expect(kase.transitions.size).to eq 5
        transition = kase.transitions.last

        expect(transition.event).to eq "add_responses"
        expect(transition.acting_team_id).to eq responding_team.id
        expect(transition.acting_user_id).to eq responder.id
        expect(transition.target_team_id).to eq disclosure_team.id
        # expect(transition.target_user_id).to eq responder.id
      end
    end

    describe :approved_ico_foi_case do
      it "creates a case in responded state" do
        kase = create :approved_ico_foi_case,
                      responding_team:,
                      responder:,
                      approver: disclosure_specialist

        expect(kase.current_state).to eq "awaiting_dispatch"
        expect(kase.assignments.size).to eq 3

        expect(kase.transitions.size).to eq 6
        transition = kase.transitions.last
        expect(transition.event).to eq "approve"
        expect(transition.acting_team_id).to eq disclosure_team.id
        expect(transition.acting_user_id).to eq disclosure_specialist.id
        expect(transition.target_team_id).to be_nil
        expect(transition.target_user_id).to be_nil
        expect(transition.to_workflow).to be_nil
      end
    end

    describe :responded_ico_foi_case do
      it "creates a case in responded state" do
        kase = create(:responded_ico_foi_case,
                      responding_team:,
                      responder:)

        expect(kase.current_state).to eq "responded"
        expect(kase.assignments.size).to eq 3
        expect(kase.date_responded).to eq Time.zone.today

        expect(kase.transitions.size).to eq 7
        transition = kase.transitions.last
        expect(transition.event).to eq "respond"
        expect(transition.acting_team_id).to eq disclosure_team.id
        expect(transition.acting_user_id).to eq disclosure_specialist.id
        expect(transition.target_team_id).to be_nil
        expect(transition.target_user_id).to be_nil
        expect(transition.to_workflow).to be_nil
      end
    end
  end

  context "when ICO SAR cases" do
    let(:responding_team) { find_or_create :sar_responding_team }
    let(:responder)       { find_or_create :sar_responder }

    describe :ico_sar_case do
      it "creates an unassigned ICO SAR case" do
        Timecop.freeze(frozen_time) do
          kase = create :ico_sar_case
          expect(kase).to be_instance_of(Case::ICO::SAR)
          expect(kase.created_at).to eq Time.zone.local(2018, 7, 3, 10, 35, 22)
          expect(kase.ico_reference_number).to match(/^ICOSARREFNUM\d{3}$/)
          expect(kase.ico_officer_name).to match(/ ico officer name \d+$/)
          expect(kase.current_state).to eq "unassigned"
          expect(kase.external_deadline).to eq Date.new(2018, 8, 6)
          expect(kase.internal_deadline).to eq Date.new(2018, 7, 23)
          expect(kase.workflow).to eq "trigger"
          expect(kase.managing_team).to eq disclosure_bmt
          expect(kase.assignments.size).to eq 2

          managing_assignment = kase.assignments.first
          expect(managing_assignment.state).to eq "accepted"
          expect(managing_assignment.team).to eq disclosure_bmt
          expect(managing_assignment.role).to eq "managing"

          expect(kase.transitions.size).to eq 2
        end
      end
    end

    describe :awaiting_responder_ico_sar_case do
      it "creates an assigned ICO SAR case" do
        Timecop.freeze(frozen_time) do
          kase = create(:awaiting_responder_ico_sar_case, responding_team:)
          expect(kase.current_state).to eq "awaiting_responder"

          expect(kase.assignments.size).to eq 3
          responding_assignment = kase.assignments.responding.first
          expect(responding_assignment.team).to eq responding_team
          expect(responding_assignment.user).to be_nil
          expect(responding_assignment.state).to eq "pending"

          expect(kase.transitions.size).to eq 3
          transition = kase.transitions.last
          expect(transition.event).to eq "assign_responder"
          expect(transition.acting_team_id).to eq disclosure_bmt.id
          expect(transition.target_team_id).to eq responding_team.id
          expect(transition.target_user_id).to be_nil
          expect(transition.to_workflow).to be_nil
        end
      end
    end

    describe :accepted_ico_sar_case do
      it "creates an case in drafting state" do
        kase = create(:accepted_ico_sar_case, responding_team:, responder:)
        expect(kase.current_state).to eq "drafting"
        expect(kase.assignments.size).to eq 3
        responding_assignment = kase.assignments.responding.first
        expect(responding_assignment.team).to eq responding_team
        expect(responding_assignment.user).to eq responder
        expect(responding_assignment.state).to eq "accepted"

        expect(kase.transitions.size).to eq 4
        transition = kase.transitions.last
        expect(transition.event).to eq "accept_responder_assignment"
        expect(transition.acting_team_id).to eq responding_team.id
        expect(transition.acting_user_id).to eq responder.id
        expect(transition.target_team_id).to be_nil
        expect(transition.target_user_id).to be_nil
        expect(transition.to_workflow).to be_nil
      end
    end

    describe :pending_dacu_clearance_ico_sar_case do
      it "creates a pending_dacu_clearance_case" do
        kase = create :pending_dacu_clearance_ico_sar_case,
                      responding_team:,
                      responder:,
                      approver: disclosure_specialist

        expect(kase.current_state).to eq "pending_dacu_clearance"
        expect(kase.assignments.size).to eq 3
        approving_assignment = kase.assignments.approving.first
        expect(approving_assignment.team).to eq disclosure_team
        expect(approving_assignment.user).to eq disclosure_specialist
        expect(approving_assignment.state).to eq "accepted"

        expect(kase.transitions.size).to eq 5
        transition = kase.transitions.last
        expect(transition.event).to eq "progress_for_clearance"
        expect(transition.acting_team_id).to eq responding_team.id
        expect(transition.acting_user_id).to eq responder.id
        expect(transition.target_team_id).to eq disclosure_team.id
      end
    end

    describe :approved_ico_sar_case do
      it "creates a case in awaiting_dispatch state" do
        kase = create :approved_ico_sar_case,
                      responding_team:,
                      responder:,
                      approver: disclosure_specialist

        expect(kase).to be_instance_of(Case::ICO::SAR)
        expect(kase.current_state).to eq "awaiting_dispatch"
        expect(kase.assignments.size).to eq 3

        expect(kase.transitions.size).to eq 6
        transition = kase.transitions.last
        expect(transition.event).to eq "approve"
        expect(transition.acting_team_id).to eq disclosure_team.id
        expect(transition.acting_user_id).to eq disclosure_specialist.id
        expect(transition.target_team_id).to be_nil
        expect(transition.target_user_id).to be_nil
        expect(transition.to_workflow).to be_nil
      end
    end

    describe :responded_ico_sar_case do
      it "creates a case in responded state" do
        kase = create :responded_ico_sar_case,
                      responding_team:,
                      responder:,
                      approver: disclosure_specialist

        expect(kase).to be_instance_of(Case::ICO::SAR)
        expect(kase.current_state).to eq "responded"
        expect(kase.assignments.size).to eq 3

        expect(kase.transitions.size).to eq 7
        transition = kase.transitions.last
        expect(transition.event).to eq "respond"
        expect(transition.acting_team_id).to eq disclosure_team.id
        expect(transition.acting_user_id).to eq disclosure_specialist.id
        expect(transition.target_team_id).to be_nil
        expect(transition.target_user_id).to be_nil
        expect(transition.to_workflow).to be_nil
      end
    end

    describe :closed_ico_sar_case do
      it "creates a case in responded state" do
        kase = create :closed_ico_sar_case,
                      responding_team:,
                      responder:,
                      approver: disclosure_specialist

        expect(kase).to be_instance_of(Case::ICO::SAR)
        expect(kase.current_state).to eq "closed"
        expect(kase.assignments.size).to eq 3

        expect(kase.transitions.size).to eq 8
        transition = kase.transitions.last
        expect(transition.event).to eq "close"
        expect(transition.acting_team_id).to eq disclosure_bmt.id
        expect(transition.acting_user_id).to eq manager.id
        expect(transition.target_team_id).to be_nil
        expect(transition.target_user_id).to be_nil
        expect(transition.to_workflow).to be_nil
      end
    end
  end
end
