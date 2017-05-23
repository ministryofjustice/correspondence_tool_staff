require 'rails_helper'

describe CasePolicy do
  subject { described_class }

  let(:managing_team)     { create :team_dacu }
  let(:manager)           { managing_team.managers.first }
  let(:responding_team)   { create :responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:coworker)          { create :responder,
                                   responding_teams: [responding_team] }
  let(:another_responder) { create :responder}
  let(:approving_team)    { create :team_dacu_disclosure }
  let(:approver)          { approving_team.approvers.first }
  let(:co_approver)       { create :approver, approving_teams: [approving_team] }

  let(:new_case)                { create :case }
  let(:accepted_case)           { create :accepted_case,
                                         responder: responder,
                                         manager: manager }
  let(:flagged_accepted_case)           { create :accepted_case, :flagged,
                                          responder: responder,
                                          manager: manager }
  let(:assigned_case)           { create :assigned_case,
                                    responding_team: responding_team }
  let(:assigned_flagged_case)   { create :assigned_case, :flagged,
                                         approving_team: approving_team}
  let(:assigned_trigger_case)   { create :assigned_case, :flagged_accepted,
                                         approver: approver }
  let(:rejected_case)           { create :rejected_case,
                                         responding_team: responding_team }
  let(:unassigned_case)         { new_case }
  let(:unassigned_flagged_case) { create :case, :flagged,
                                         approving_team: approving_team }
  let(:unassigned_trigger_case) { create :case, :flagged_accepted,
                                         approving_team: approving_team }
  let(:case_with_response)      { create :case_with_response,
                                         responder: responder }
  let(:responded_case)          { create :responded_case,
                                         responder: responder }
  let(:closed_case)             { create :closed_case,
                                         responder: responder }
  let(:pending_dacu_clearance_case) { create :pending_dacu_clearance_case }

  permissions :can_accept_or_reject_approver_assignment? do
    it { should_not permit(manager,           unassigned_flagged_case) }
    it { should_not permit(responder,         unassigned_flagged_case) }
    it { should_not permit(another_responder, unassigned_flagged_case) }
    it { should     permit(approver,          unassigned_flagged_case) }
    it { should_not permit(approver,          unassigned_trigger_case) }
  end

  permissions :can_accept_or_reject_responder_assignment? do
    it { should_not permit(manager,           assigned_case) }
    it { should     permit(responder,         assigned_case) }
    it { should_not permit(another_responder, assigned_case) }
    it { should_not permit(approver,          assigned_case) }
  end

  permissions :can_add_attachment? do
    context 'in drafting state' do
      it { should_not permit(manager,           accepted_case) }
      it { should     permit(responder,         accepted_case) }
      it { should     permit(coworker,          accepted_case) }
      it { should_not permit(another_responder, accepted_case) }
    end

    context 'in awaiting_dispatch state' do
      context 'flagged case' do
        it { should_not permit(manager,           flagged_accepted_case) }
        it { should_not permit(responder,         flagged_accepted_case) }
        it { should_not permit(coworker,          flagged_accepted_case) }
        it { should_not permit(another_responder, flagged_accepted_case) }
      end

      context 'unflagged_case' do

        it { should_not permit(manager,           case_with_response) }
        it { should     permit(responder,         case_with_response) }
        it { should     permit(coworker,          case_with_response) }
        it { should_not permit(another_responder, case_with_response) }
      end
    end
  end

  permissions :can_add_attachment_to_flagged_case? do
    context 'in awiting dispatch_state' do
      context 'flagged case' do
        it { should_not permit(manager,           flagged_accepted_case) }
        it { should     permit(responder,         flagged_accepted_case) }
        it { should     permit(coworker,          flagged_accepted_case) }
        it { should_not permit(another_responder, flagged_accepted_case) }
      end

      context 'unflagged case' do
        it { should_not permit(manager,           accepted_case) }
        it { should_not permit(responder,         accepted_case) }
        it { should_not permit(coworker,          accepted_case) }
        it { should_not permit(another_responder, accepted_case) }
      end
    end
  end

  permissions :can_add_case? do
    it { should_not permit(responder, new_case) }
    it { should     permit(manager,   new_case) }
  end

  permissions :can_assign_case? do
    it { should_not permit(responder, new_case) }
    it { should     permit(manager,   new_case) }
    it { should_not permit(manager,   assigned_case) }
    it { should_not permit(responder, assigned_case) }
  end

  permissions :can_close_case? do
    it { should_not permit(responder, responded_case) }
    it { should     permit(manager,   responded_case) }
  end

  permissions :can_flag_for_clearance? do
    it { should_not permit(responder, assigned_case) }
    it { should     permit(manager,   assigned_case) }
    it { should     permit(approver,  assigned_case) }
    it { should_not permit(responder, assigned_flagged_case) }
    it { should_not permit(manager,   assigned_flagged_case) }
    it { should_not permit(approver,  assigned_flagged_case) }
  end

  permissions :can_remove_attachment? do
    context 'case is still being drafted' do
      it { should     permit(responder,         case_with_response) }
      it { should_not permit(another_responder, case_with_response) }
      it { should_not permit(manager,           case_with_response) }
    end

    context 'case has been marked as responded' do
      it { should_not permit(another_responder, responded_case) }
      it { should_not permit(manager,           responded_case) }
    end
  end

  permissions :can_respond? do
    it { should_not permit(manager,           case_with_response) }
    it { should     permit(responder,         case_with_response) }
    it { should     permit(coworker,          case_with_response) }
    it { should_not permit(another_responder, case_with_response) }
    it { should_not permit(responder,         accepted_case) }
    it { should_not permit(coworker,          accepted_case) }
  end

  permissions :can_unflag_for_clearance? do
    it { should_not permit(responder, assigned_case) }
    it { should_not permit(manager,   assigned_case) }
    it { should_not permit(approver,  assigned_case) }
    it { should_not permit(responder, assigned_flagged_case) }
    it { should     permit(manager,   assigned_flagged_case) }
    it { should     permit(approver,  assigned_flagged_case) }
  end

  permissions :can_approve? do
    it { should     permit(pending_dacu_clearance_case.approver,   pending_dacu_clearance_case) }
    it { should_not permit(approver,   new_case) }
    it { should_not permit(approver,   accepted_case) }
    it { should_not permit(approver,   assigned_case) }
    it { should_not permit(approver,   rejected_case) }
    it { should_not permit(approver,   unassigned_case) }
    it { should_not permit(approver,   unassigned_flagged_case) }
    it { should_not permit(approver,   unassigned_trigger_case) }
    it { should_not permit(approver,   case_with_response) }
    it { should_not permit(approver,   responded_case) }
    it { should_not permit(approver,   closed_case) }

    it { should_not permit(co_approver,   assigned_trigger_case) }
    it { should_not permit(co_approver,   new_case) }
    it { should_not permit(co_approver,   accepted_case) }
    it { should_not permit(co_approver,   assigned_case) }
    it { should_not permit(co_approver,   rejected_case) }
    it { should_not permit(co_approver,   unassigned_case) }
    it { should_not permit(co_approver,   unassigned_flagged_case) }
    it { should_not permit(co_approver,   unassigned_trigger_case) }
    it { should_not permit(co_approver,   case_with_response) }
    it { should_not permit(co_approver,   responded_case) }
    it { should_not permit(co_approver,   closed_case) }


    it { should_not permit(manager,   assigned_trigger_case) }
    it { should_not permit(manager,   new_case) }
    it { should_not permit(manager,   accepted_case) }
    it { should_not permit(manager,   assigned_case) }
    it { should_not permit(manager,   rejected_case) }
    it { should_not permit(manager,   unassigned_case) }
    it { should_not permit(manager,   unassigned_flagged_case) }
    it { should_not permit(manager,   unassigned_trigger_case) }
    it { should_not permit(manager,   case_with_response) }
    it { should_not permit(manager,   responded_case) }
    it { should_not permit(manager,   closed_case) }

    it { should_not permit(responder,   assigned_trigger_case) }
    it { should_not permit(responder,   new_case) }
    it { should_not permit(responder,   accepted_case) }
    it { should_not permit(responder,   assigned_case) }
    it { should_not permit(responder,   rejected_case) }
    it { should_not permit(responder,   unassigned_case) }
    it { should_not permit(responder,   unassigned_flagged_case) }
    it { should_not permit(responder,   unassigned_trigger_case) }
    it { should_not permit(responder,   case_with_response) }
    it { should_not permit(responder,   responded_case) }
    it { should_not permit(responder,   closed_case) }
  end

  permissions :can_view_case_details? do
    it { should     permit(manager,           new_case) }
    it { should     permit(manager,           assigned_case) }
    it { should     permit(manager,           accepted_case) }
    it { should     permit(manager,           rejected_case) }
    it { should     permit(manager,           case_with_response) }
    it { should     permit(manager,           responded_case) }
    it { should     permit(manager,           closed_case) }
    it { should_not permit(responder,         new_case) }
    it { should     permit(responder,         assigned_case) }
    it { should     permit(responder,         accepted_case) }
    it { should_not permit(responder,         rejected_case) }
    it { should     permit(responder,         case_with_response) }
    it { should_not permit(responder,         responded_case) }
    it { should_not permit(responder,         closed_case) }
    it { should_not permit(coworker,          new_case) }
    it { should     permit(coworker,          assigned_case) }
    it { should     permit(coworker,          accepted_case) }
    it { should_not permit(coworker,          rejected_case) }
    it { should     permit(coworker,          case_with_response) }
    it { should_not permit(coworker,          responded_case) }
    it { should_not permit(coworker,          closed_case) }
    it { should_not permit(another_responder, new_case) }
    it { should_not permit(another_responder, assigned_case) }
    it { should_not permit(another_responder, rejected_case) }
    it { should_not permit(another_responder, accepted_case) }
    it { should_not permit(another_responder, case_with_response) }
    it { should_not permit(another_responder, responded_case) }
    it { should_not permit(another_responder, closed_case) }
    it { should     permit(approver,          assigned_flagged_case) }
    it { should     permit(approver,          assigned_trigger_case) }
    it { should     permit(co_approver,       assigned_flagged_case) }
    it { should     permit(co_approver,       assigned_trigger_case) }
    it { should_not permit(approver,          assigned_case) }
    it { should_not permit(approver,          assigned_case) }
  end

  describe 'case scope policy' do
    let(:existing_cases) do
      [
        unassigned_case,
        assigned_case,
        accepted_case,
        rejected_case,
        case_with_response,
        responded_case,
        closed_case,
      ]
    end

    it 'for managers - returns all cases' do
      existing_cases
      manager_scope = described_class::Scope.new(manager, Case.all).resolve
      expect(manager_scope).to match_array(existing_cases)
    end

    it 'for responders - returns only their cases' do
      existing_cases
      responder_scope = described_class::Scope.new(responder, Case.all).resolve
      expect(responder_scope).to match_array([assigned_case, accepted_case, case_with_response])
    end

  end
end
