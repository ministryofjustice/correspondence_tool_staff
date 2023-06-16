require "rails_helper"

describe Case::FOI::StandardPolicy do
  subject { described_class }

  # Teams
  let(:managing_team)         { find_or_create :team_dacu }
  let(:responding_team)       { create :responding_team }
  let!(:dacu_disclosure)      { find_or_create :team_dacu_disclosure }

  # Users
  let(:manager)               { managing_team.managers.first }
  let(:responder)             { find_or_create :responder }
  let(:press_officer)         { find_or_create :press_officer }
  let(:private_officer)       { find_or_create :private_officer }
  let(:disclosure_specialist) { dacu_disclosure.approvers.first }
  let(:branston_user)         { find_or_create :branston_user }

  # Cases
  # Unflagged
  let(:unassigned_case)               { create :case }
  let(:accepted_case)                 do
    create :accepted_case,
           responder:,
           manager:
  end
  let(:pending_dacu_clearance_case) do
    create :pending_dacu_clearance_case,
           approver: disclosure_specialist
  end
  let(:pending_press_clearance_case) do
    create :pending_press_clearance_case,
           press_officer:
  end
  let(:pending_private_clearance_case) do
    create :pending_private_clearance_case,
           private_officer:
  end
  let(:responded_case) do
    create :responded_case,
           responder:
  end
  let(:closed_case) do
    create :closed_case,
           responder:
  end
  let(:case_with_response) do
    create :case_with_response,
           responder:
  end
  let(:approved_case) { create :approved_case }
  let(:unassigned_case_within_escalation) do
    create :case_within_escalation_deadline
  end

  # Flagged case (cases not yet accepted by approvers)

  let(:accepted_trigger_case) do
    create :accepted_case,
           :flagged,
           :dacu_disclosure
  end
  let(:accepted_press_case) do
    create :accepted_case,
           :flagged,
           :press_office
  end
  let(:accepted_flagged_case) do
    create :accepted_case,
           :flagged,
           :dacu_disclosure
  end
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
    it { is_expected.not_to permit(responder,             accepted_case) }
    it { is_expected.to     permit(manager,               accepted_case) }
    it { is_expected.to     permit(manager,               case_with_response) }
    it { is_expected.to     permit(manager,               unassigned_case) }
    it { is_expected.not_to permit(manager,               closed_case) }
    it { is_expected.not_to permit(disclosure_specialist, accepted_case) }
    it { is_expected.not_to permit(press_officer,         accepted_case) }
    it { is_expected.not_to permit(private_officer,       accepted_case) }
  end

  permissions :can_request_further_clearance? do
    it { is_expected.to     permit(manager, unassigned_case_within_escalation) }
    it { is_expected.not_to permit(manager, unassigned_flagged_case_within_escalation) }
    it { is_expected.not_to permit(manager, unassigned_trigger_case_within_escalation) }
    it { is_expected.not_to permit(manager, unassigned_press_case_within_escalation) }
    it { is_expected.to     permit(manager, accepted_case) }
    it { is_expected.to     permit(manager, accepted_flagged_case) }
    it { is_expected.to     permit(manager, accepted_trigger_case) }
    it { is_expected.not_to permit(manager, accepted_press_case) }
    it { is_expected.to     permit(manager, pending_dacu_clearance_case) }
    it { is_expected.not_to permit(manager, responded_case) }
    it { is_expected.to     permit(manager, approved_case) }
  end

  permissions :execute_request_amends? do
    it { is_expected.not_to permit(responder,             pending_press_clearance_case) }
    it { is_expected.not_to permit(disclosure_specialist, pending_press_clearance_case) }
    it { is_expected.to     permit(press_officer,         pending_press_clearance_case) }
    it { is_expected.not_to permit(private_officer,       pending_press_clearance_case) }
    it { is_expected.not_to permit(responder,             pending_private_clearance_case) }
    it { is_expected.not_to permit(disclosure_specialist, pending_private_clearance_case) }
    it { is_expected.not_to permit(press_officer,         pending_private_clearance_case) }
    it { is_expected.to     permit(private_officer,       pending_private_clearance_case) }
  end

  permissions :show? do
    it { is_expected.to     permit(manager,               unassigned_case) }
    it { is_expected.not_to permit(branston_user,         unassigned_case) }
    it { is_expected.to     permit(responder,             unassigned_case) }
    it { is_expected.to     permit(disclosure_specialist, unassigned_case) }
  end
end
