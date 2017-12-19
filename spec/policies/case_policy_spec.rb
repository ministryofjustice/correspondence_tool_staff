require 'rails_helper'


describe CasePolicy do
  let!(:dacu_disclosure)  { find_or_create :team_dacu_disclosure }
  let(:managing_team)     { find_or_create :team_dacu }
  let(:manager)           { managing_team.managers.first }
  let(:responding_team)   { create :responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:approver)          { dacu_disclosure.approvers.first }

  let(:new_case)                { create :case }
  let(:unassigned_case)         { new_case }
  let(:assigned_case)           { create :assigned_case,
                                         responding_team: responding_team }
  let(:accepted_case)           { create :accepted_case,
                                         responder: responder,
                                         manager: manager }
  let(:rejected_case)           { create :rejected_case,
                                         responding_team: responding_team }
  let(:case_with_response)      { create :case_with_response,
                                         responder: responder }
  let(:responded_case)          { create :responded_case,
                                         responder: responder }
  let(:closed_case)             { create :closed_case,
                                         responder: responder }

  let(:policy) { described_class.new(responder, new_case) }

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
      expect(responder_scope).to match_array([assigned_case,
                                              accepted_case,
                                              case_with_response,
                                              responded_case,
                                              closed_case])
    end

    it 'for approvers - returns all cases' do
      existing_cases
      approver_scope = described_class::Scope.new(approver, Case.all).resolve
      expect(approver_scope).to match_array(existing_cases)
    end

    it 'for responder & manager - returns all cases' do
      responder.team_roles << TeamsUsersRole.new(team: dacu_disclosure,
                                                 role: 'manager')
      existing_cases
      resolved_scope = described_class::Scope.new(responder, Case.all).resolve
      expect(resolved_scope).to match_array(existing_cases)
    end
  end
end
