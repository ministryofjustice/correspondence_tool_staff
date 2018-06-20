require 'rails_helper'

describe Case::FOI::StandardPolicy do
  subject { described_class }

  # Teams
  let(:managing_team)         { find_or_create :team_dacu }
  let(:responding_team)       { create :responding_team }
  let!(:dacu_disclosure)      { find_or_create :team_dacu_disclosure }

  # Users
  let(:manager)               { managing_team.managers.first }
  let(:responder)             { responding_team.responders.first }
  let(:press_officer)         { find_or_create :press_officer }
  let(:private_officer)       { find_or_create :private_officer }
  let(:disclosure_specialist) { dacu_disclosure.approvers.first }

# Cases
  # Unflagged
  let(:unassigned_case)               { create :case }
  let(:accepted_case)                 { create :accepted_case,
                                                responder: responder,
                                                manager: manager }
  let(:pending_dacu_clearance_case)   { create :pending_dacu_clearance_case,
                                        approver: disclosure_specialist }
  let(:pending_press_clearance_case)  { create :pending_press_clearance_case,
                                                press_officer: press_officer }
  let(:pending_private_clearance_case){  create :pending_private_clearance_case,
                                                private_officer: private_officer }
  let(:responded_case)                { create :responded_case,
                                                responder: responder }
  let(:closed_case)                   { create :closed_case,
                                                responder: responder }
  let(:case_with_response)            { create :case_with_response,
                                                responder: responder }
  let(:approved_case)                 { create :approved_case }
  let(:unassigned_case_within_escalation) do
    create :case_within_escalation_deadline
  end

  # Flagged case (cases not yet accepted by approvers)

  let(:accepted_trigger_case)   { create :accepted_case,
                                        :flagged,
                                        :dacu_disclosure }
  let(:accepted_press_case)      { create :accepted_case,
                                        :flagged,
                                        :press_office }
  let(:accepted_flagged_case)    { create :accepted_case,
                                        :flagged,
                                        :dacu_disclosure }
  let(:unassigned_flagged_case_within_escalation) do
    create :case_within_escalation_deadline,
      :flagged,
      :dacu_disclosure
  end

  # Trigger cases (cases that have been accepted by approvers)
  let(:unassigned_trigger_case_within_escalation) do
   create :case_within_escalation_deadline,
        :flagged_accepted,
        :dacu_disclosure
  end

  let(:unassigned_press_case_within_escalation) do
    create :case_within_escalation_deadline,
        :flagged_accepted,
        :press_office
  end

  permissions :request_further_clearance? do
    it { should_not permit(responder,             accepted_case) }
    it { should     permit(manager,               accepted_case) }
    it { should     permit(manager,               case_with_response)}
    it { should     permit(manager,               unassigned_case) }
    it { should_not permit(manager,               closed_case) }
    it { should_not permit(disclosure_specialist, accepted_case) }
    it { should_not permit(press_officer,         accepted_case) }
    it { should_not permit(private_officer,       accepted_case) }
  end

  permissions :can_request_further_clearance? do

    it { should     permit(manager, unassigned_case_within_escalation) }
    it { should_not permit(manager, unassigned_flagged_case_within_escalation) }
    it { should_not permit(manager, unassigned_trigger_case_within_escalation) }
    it { should_not permit(manager, unassigned_press_case_within_escalation) }
    it { should     permit(manager, accepted_case) }
    it { should     permit(manager, accepted_flagged_case) }
    it { should     permit(manager, accepted_trigger_case) }
    it { should_not permit(manager, accepted_press_case) }
    it { should     permit(manager, pending_dacu_clearance_case) }
    it { should_not permit(manager, responded_case) }
    it { should     permit(manager, approved_case) }
  end

  permissions :execute_request_amends? do
    it { should_not permit(responder,             pending_press_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_press_clearance_case) }
    it { should     permit(press_officer,         pending_press_clearance_case) }
    it { should_not permit(private_officer,       pending_press_clearance_case) }
    it { should_not permit(responder,             pending_private_clearance_case) }
    it { should_not permit(disclosure_specialist, pending_private_clearance_case) }
    it { should_not permit(press_officer,         pending_private_clearance_case) }
    it { should     permit(private_officer,       pending_private_clearance_case) }
  end

  permissions :show? do
    it { should     permit(manager,               unassigned_case) }
    it { should     permit(responder,             unassigned_case) }
    it { should     permit(disclosure_specialist, unassigned_case) }
  end
end
