require 'rails_helper'

describe AssignmentPolicy do
  let(:manager)         { create :manager }
  let(:responder)       { create :responder }

  let(:unassigned_case)                       { create :case }
  let(:assigned_case)                         { create :awaiting_responder_case }
  let(:drafting_case)                         { create :case_being_drafted }
  let(:case_with_response)                    { create :case_with_response }
  let(:responder_assignment_on_assigned_case) { assigned_case.responder_assignment }
  let(:responder_assignment_on_drafting_case) { drafting_case.responder_assignment }
  let(:responder_assignment_on_cwr)           { case_with_response.responder_assignment }
  let(:new_assignment_on_unassigned_case)     { Assignment.new(case_id: unassigned_case.id) }



  subject { described_class }

  permissions :can_create_for_team? do
    it { should     permit(manager,   new_assignment_on_unassigned_case) }
    it { should_not permit(manager,   responder_assignment_on_assigned_case) }
    it { should     permit(responder, new_assignment_on_unassigned_case) }
  end

  permissions :can_assign_to_new_team? do
    it { should     permit(manager,   responder_assignment_on_drafting_case ) }
    it { should     permit(manager,   responder_assignment_on_assigned_case ) }
    it { should_not permit(manager,   responder_assignment_on_cwr) }
    it { should_not permit(responder, responder_assignment_on_drafting_case ) }
    it { should_not permit(responder, responder_assignment_on_assigned_case ) }
    it { should_not permit(responder, responder_assignment_on_cwr) }
  end

end
