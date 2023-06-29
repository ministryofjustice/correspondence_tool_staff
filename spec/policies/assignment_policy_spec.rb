require "rails_helper"

describe AssignmentPolicy do
  subject { described_class }

  let(:manager)         { find_or_create :disclosure_bmt_user }
  let(:responder)       { find_or_create :foi_responder }

  let(:unassigned_case)                       { create :case }
  let(:assigned_case)                         { create :awaiting_responder_case }
  let(:drafting_case)                         { create :case_being_drafted }
  let(:case_with_response)                    { create :case_with_response }
  let(:responder_assignment_on_assigned_case) { assigned_case.responder_assignment }
  let(:responder_assignment_on_drafting_case) { drafting_case.responder_assignment }
  let(:responder_assignment_on_cwr)           { case_with_response.responder_assignment }
  let(:new_assignment_on_unassigned_case)     { Assignment.new(case_id: unassigned_case.id) }

  permissions :can_create_for_team? do
    it { is_expected.to     permit(manager,   new_assignment_on_unassigned_case) }
    it { is_expected.not_to permit(manager,   responder_assignment_on_assigned_case) }
    it { is_expected.to     permit(responder, new_assignment_on_unassigned_case) }
  end

  permissions :can_assign_to_new_team? do
    it { is_expected.to     permit(manager,   responder_assignment_on_drafting_case) }
    it { is_expected.to     permit(manager,   responder_assignment_on_assigned_case) }
    it { is_expected.not_to permit(manager,   responder_assignment_on_cwr) }
    it { is_expected.not_to permit(responder, responder_assignment_on_drafting_case) }
    it { is_expected.not_to permit(responder, responder_assignment_on_assigned_case) }
    it { is_expected.not_to permit(responder, responder_assignment_on_cwr) }
  end
end
