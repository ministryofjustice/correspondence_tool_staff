require 'rails_helper'

describe CasePolicy do
  subject { described_class }

  let(:responding_team)   { create :responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:coworker)          { create :responder,
                                   responding_teams: [responding_team] }
  let(:another_responder) { create :responder}
  let(:managing_team)     { create :team_dacu }
  let(:manager)           { managing_team.managers.first }

  let(:new_case) { create :case }
  let(:accepted_case) do
    create :accepted_case, responder: responder, manager: manager
  end
  let(:assigned_case)      { create :assigned_case,
                                    responding_team: responding_team }
  let(:rejected_case)      { create :rejected_case,
                                    responding_team: responding_team }
  let(:unassigned_case)    { new_case }
  let(:case_with_response) { create(:case_with_response, responder: responder) }
  let(:responded_case)     { create(:responded_case, responder: responder) }
  let(:closed_case)        { create(:closed_case, responder: responder) }

  permissions :can_accept_or_reject_case? do
    it { should_not permit(manager,           assigned_case) }
    it { should     permit(responder,         assigned_case) }
    it { should_not permit(another_responder, assigned_case) }
  end

  permissions :can_add_attachment? do
    context 'in drafting state' do
      it { should_not permit(manager,           accepted_case) }
      it { should     permit(responder,         accepted_case) }
      it { should     permit(coworker,          accepted_case) }
      it { should_not permit(another_responder, accepted_case) }
    end

    context 'in awaiting_dispatch state' do
      it { should_not permit(manager,           case_with_response) }
      it { should     permit(responder,         case_with_response) }
      it { should     permit(coworker,          case_with_response) }
      it { should_not permit(another_responder, case_with_response) }
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

  permissions :can_respond? do
    it { should_not permit(manager,           case_with_response) }
    it { should     permit(responder,         case_with_response) }
    it { should     permit(coworker,          case_with_response) }
    it { should_not permit(another_responder, case_with_response) }
    it { should_not permit(responder,         accepted_case) }
    it { should_not permit(coworker,          accepted_case) }
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
      expect(manager_scope).to eq existing_cases
    end

    it 'for responders - returns only their cases' do
      existing_cases
      responder_scope = described_class::Scope.new(responder, Case.all).resolve
      expect(responder_scope).to eq [assigned_case, accepted_case, case_with_response]
    end

  end
end
