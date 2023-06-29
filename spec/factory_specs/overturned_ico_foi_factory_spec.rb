require "rails_helper"

describe "Overturned ICO FOI cases factory" do
  let(:frozen_time)             { Time.zone.local(2018, 7, 9, 10, 35, 22) }
  let(:disclosure_bmt)          { find_or_create :team_disclosure_bmt }
  let(:manager)                 { disclosure_bmt.users.first }
  let(:responding_team)         { find_or_create :foi_responding_team }
  let(:responder)               { find_or_create :foi_responder }
  let(:disclosure_team)         { find_or_create :team_disclosure }
  let(:disclosure_specialist)   { disclosure_team.users.first }
  let(:press_office)            { find_or_create :team_press_office }
  let(:press_officer)           { press_office.approvers.first }
  let(:private_office)          { find_or_create :team_private_office }
  let(:private_officer)         { private_office.approvers.first }

  def assignment_for(kase, team)
    kase.assignments
      .approving
      .accepted
      .where(team:)
      .singular
  end

  def disclosure_assignment_for(kase)
    assignment_for(kase, disclosure_team)
  end

  def press_assignment_for(kase)
    assignment_for(kase, press_office)
  end

  def private_assignment_for(kase)
    assignment_for(kase, private_office)
  end

  describe ":overturned_ico_foi" do
    it "creates an unassigned ICO Overturned FOI" do
      Timecop.freeze(frozen_time) do
        kase = create :overturned_ico_foi
        expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
        expect(kase.created_at).to eq Time.zone.local(2018, 7, 3, 10, 35, 22)
        expect(kase.ico_reference_number).to match(/^ICOFOIREFNUM\d{3}$/)
        expect(kase.current_state).to eq "unassigned"
        expect(kase.external_deadline).to eq Date.new(2018, 7, 29)
        expect(kase.internal_deadline).to eq Date.new(2018, 6, 29)
        expect(kase.workflow).to eq "standard"
        expect(kase.managing_team).to eq disclosure_bmt
        expect(kase.assignments.size).to eq 1

        managing_assignment = kase.assignments.first
        expect(managing_assignment.state).to eq "accepted"
        expect(managing_assignment.team).to eq disclosure_bmt
        expect(managing_assignment.role).to eq "managing"

        expect(kase.transitions.size).to eq 1
      end
    end
  end

  describe ":awaiting_responder_ot_ico_foi" do
    it "creates an assigned ICO Overturned FOI" do
      Timecop.freeze(frozen_time) do
        kase = create(:awaiting_responder_ot_ico_foi, responding_team:)
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

  describe ":accepted_ot_ico_foi" do
    it "creates an ICO Overturned FOI in drafting state" do
      kase = create(:accepted_ot_ico_foi, responding_team:, responder:)
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

  describe ":with_response_ot_ico_foi" do
    it "creates an ICO Overturned FOI with a response" do
      kase = create(:with_response_ot_ico_foi,
                    responding_team:,
                    responder:)
      expect(kase.current_state).to eq "awaiting_dispatch"

      expect(kase.transitions.size).to eq 4
      transition = kase.transitions.last
      expect(transition.event).to eq "add_responses"
      expect(transition.acting_team_id).to eq responding_team.id
      expect(transition.acting_user_id).to eq responder.id
      expect(transition.target_team_id).to be_nil
      expect(transition.target_user_id).to be_nil
      expect(transition.to_workflow).to be_nil
    end
  end

  describe ":pending_dacu_clearance_ot_ico_foi" do
    it "create an ICO Overturned FOI that is pending disclosure clearance" do
      kase = create :pending_dacu_clearance_ot_ico_foi,
                    responding_team:,
                    responder:,
                    approving_team: disclosure_team,
                    approver: disclosure_specialist

      expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
      expect(kase.current_state).to eq "pending_dacu_clearance"

      expect(kase.transitions.size).to eq 6
      expect(kase.workflow).to eq "trigger"
      transition = kase.transitions.last
      expect(transition.event).to eq "add_responses"
      expect(transition.acting_team_id).to eq responding_team.id
      expect(transition.acting_user_id).to eq responder.id
      expect(transition.target_team_id).to be_nil
      expect(transition.target_user_id).to be_nil
      expect(kase.assignments.approving.accepted.count).to eq 1
      expect(kase.assignments.approving.accepted[0].team_id).to eq disclosure_team.id
      expect(kase.assignments.approving.accepted[0].approved).to be_falsey
    end
  end

  describe ":approved_trigger_ot_ico_foi" do
    it "create a trigger ICO Overturned FOI that has been approved" do
      kase = create :approved_trigger_ot_ico_foi

      expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
      expect(kase.current_state).to eq "awaiting_dispatch"
      expect(kase.workflow).to eq "trigger"

      expect(kase.transitions.size).to eq 7
      transition = kase.transitions.last
      expect(transition.event).to eq "approve"
      expect(transition.acting_team_id).to eq disclosure_team.id
      expect(transition.acting_user_id).to eq disclosure_specialist.id

      expect(kase.assignments.approving.accepted.count).to eq 1
      expect(disclosure_assignment_for(kase)).to be_approved
    end
  end

  describe ":pending_press_clearance_ot_ico_foi" do
    it "create a full-approval ICO Overturned FOI case that is pending press office clearance" do
      kase = create :pending_press_clearance_ot_ico_foi

      expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
      expect(kase.current_state).to eq "pending_press_office_clearance"
      expect(kase.workflow).to eq "full_approval"

      expect(kase.transitions.size).to eq 9
      transition = kase.transitions.last
      expect(transition.event).to eq "approve"
      expect(transition.acting_team_id).to eq disclosure_team.id
      expect(transition.acting_user_id).to eq disclosure_specialist.id

      expect(kase.assignments.approving.accepted.count).to eq 3
      expect(disclosure_assignment_for(kase)).to be_approved
      expect(press_assignment_for(kase)).not_to be_approved
      expect(private_assignment_for(kase)).not_to be_approved
    end
  end

  describe ":pending_private_clearance_ot_ico_foi" do
    it "create a full-approval ICO Overturned FOI that is pending press office clearance" do
      kase = create :pending_private_clearance_ot_ico_foi

      expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
      expect(kase.current_state).to eq "pending_private_office_clearance"
      expect(kase.workflow).to eq "full_approval"

      expect(kase.transitions.size).to eq 10
      transition = kase.transitions.last
      expect(transition.event).to eq "approve"
      expect(transition.acting_team_id).to eq press_office.id
      expect(transition.acting_user_id).to eq press_officer.id

      expect(kase.assignments.approving.accepted.count).to eq 3
      expect(disclosure_assignment_for(kase)).to be_approved
      expect(press_assignment_for(kase)).to be_approved
      expect(private_assignment_for(kase)).not_to be_approved
    end
  end

  describe ":approved_full_approval_ot_ico_foi" do
    it "create a full-approval ICO Overturned FOI that has been fully approved" do
      kase = create :approved_full_approval_ot_ico_foi

      expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
      expect(kase.current_state).to eq "awaiting_dispatch"
      expect(kase.workflow).to eq "full_approval"

      expect(kase.transitions.size).to eq 11
      transition = kase.transitions.last
      expect(transition.event).to eq "approve"
      expect(transition.acting_team_id).to eq private_office.id
      expect(transition.acting_user_id).to eq private_officer.id

      expect(kase.assignments.approving.accepted.count).to eq 3
      expect(disclosure_assignment_for(kase)).to be_approved
      expect(press_assignment_for(kase)).to be_approved
      expect(private_assignment_for(kase)).to be_approved
    end
  end

  describe ":responded_ot_ico_foi" do
    it "creates an ICO Overturned FOI case that has been responded state" do
      kase = create(:responded_ot_ico_foi,
                    responding_team:,
                    responder:)

      expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
      expect(kase.current_state).to eq "responded"

      expect(kase.transitions.size).to eq 5
      transition = kase.transitions.last
      expect(transition.event).to eq "respond"
      expect(transition.acting_team_id).to eq responding_team.id
      expect(transition.acting_user_id).to eq responder.id
      expect(transition.to_workflow).to be_nil
    end
  end

  describe ":responded_trigger_ot_ico_foi" do
    it "creates a trigger ICO Overturned FOI case that has been responded" do
      kase = create(:responded_trigger_ot_ico_foi,
                    responding_team:,
                    responder:)

      expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
      expect(kase.current_state).to eq "responded"
      expect(kase.workflow).to eq "trigger"

      expect(kase.transitions.size).to eq 8
      transition = kase.transitions.last
      expect(transition.event).to eq "respond"
      expect(transition.acting_team_id).to eq responding_team.id
      expect(transition.acting_user_id).to eq responder.id
      expect(transition.to_workflow).to be_nil

      expect(kase.assignments.approving.accepted.count).to eq 1
      expect(disclosure_assignment_for(kase)).to be_approved
    end
  end

  describe ":responded_full_approval_ot_ico_foi" do
    it "creates a full-approval ICO Overturned FOI case that has been responded" do
      kase = create(:responded_full_approval_ot_ico_foi,
                    responding_team:,
                    responder:)
      expect(kase.current_state).to eq "responded"
      expect(kase.workflow).to eq "full_approval"

      expect(kase.transitions.size).to eq 12
      transition = kase.transitions.last
      expect(transition.event).to eq "respond"
      expect(transition.acting_team_id).to eq responding_team.id
      expect(transition.acting_user_id).to eq responder.id
      expect(transition.to_workflow).to be_nil
      expect(kase.assignments.approving.accepted.count).to eq 3
      expect(disclosure_assignment_for(kase)).to be_approved
      expect(press_assignment_for(kase)).to be_approved
      expect(private_assignment_for(kase)).to be_approved
    end
  end

  describe ":closed_ot_ico_foi" do
    it "creates an ICO Overturned FOI case that is closed" do
      kase = create(:closed_ot_ico_foi,
                    responding_team:,
                    responder:)

      expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
      expect(kase.current_state).to eq "closed"
      expect(kase.assignments.size).to eq 2

      expect(kase.transitions.size).to eq 6
      transition = kase.transitions.last
      expect(transition.event).to eq "close"
      expect(transition.acting_team).to eq disclosure_bmt
      expect(transition.acting_user).to eq manager
      expect(transition.to_workflow).to be_nil
    end
  end

  describe ":closed_trigger_ot_ico_foi" do
    it "creates a trigger ICO Overturned FOI case that is closed" do
      kase = create(:closed_trigger_ot_ico_foi,
                    responding_team:,
                    responder:)

      expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
      expect(kase.current_state).to eq "closed"
      expect(kase.workflow).to eq "trigger"

      expect(kase.transitions.size).to eq 9
      transition = kase.transitions.last
      expect(transition.event).to eq "close"
      expect(transition.acting_team).to eq disclosure_bmt
      expect(transition.acting_user).to eq manager

      expect(kase.assignments.approving.accepted.count).to eq 1
      expect(disclosure_assignment_for(kase)).to be_approved
    end
  end

  describe ":closed_full_approval_ot_ico_foi" do
    it "creates a full-approval ICO Overturned FOI case that is closed" do
      kase = create(:closed_full_approval_ot_ico_foi,
                    responding_team:,
                    responder:)

      expect(kase).to be_instance_of(Case::OverturnedICO::FOI)
      expect(kase.current_state).to eq "closed"
      expect(kase.workflow).to eq "full_approval"

      expect(kase.transitions.size).to eq 13
      transition = kase.transitions.last
      expect(transition.event).to eq "close"
      expect(transition.acting_team).to eq disclosure_bmt
      expect(transition.acting_user).to eq manager

      expect(kase.assignments.approving.accepted.count).to eq 3
      expect(disclosure_assignment_for(kase)).to be_approved
      expect(press_assignment_for(kase)).to be_approved
      expect(private_assignment_for(kase)).to be_approved
    end
  end
end
