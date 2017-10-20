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

  describe '#initialize' do
    describe 'workflow' do
      it 'is set to FOI workflow if the case workflow is not present' do
        policy = CasePolicy.new(responder, new_case)
        expect(policy.policy_workflow).to be_a(Cases::FOIPolicy)
      end

      it 'raises if the workflow is not recognised' do
        allow(new_case).to receive(:workflow).and_return('Nonexistent')
        expect {
          CasePolicy.new(responder, new_case)
        }.to raise_error(NameError, 'uninitialized constant Cases::FOI')
      end
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
  end

  describe 'missing methods' do
    it 'are delegated to the workflow object' do
      policy_workflow = spy('PolicyWorkflow')
      policy.instance_variable_set :@policy_workflow, policy_workflow
      policy.can_do_this_or_that?
      expect(policy_workflow).to have_received(:can_do_this_or_that?)
    end

    it 'can test whether the workflow responds to a method' do
      policy_workflow = double('PolicyWorkflow', can_do_this_or_that?: true)
      policy.instance_variable_set :@policy_workflow, policy_workflow
      expect(policy.respond_to?(:can_do_this_or_that?)).to eq true
    end

    it 'can test whether the workflow responds to a method' do
      policy_workflow = double('PolicyWorkflow', can_do_this_or_that?: true)
      policy.instance_variable_set :@policy_workflow, policy_workflow
      expect(policy.respond_to?(:nonexistant_hat?)).to eq false
    end
  end
end
