require 'rails_helper'

describe Case::BasePolicy::Scope do

  describe 'case scope policy' do

    before(:all) do
      @responding_team              = find_or_create :foi_responding_team
      @responding_team_2            = create :responding_team
      @managing_team                = create :team_dacu
      @dacu_disclosure              = create :team_dacu_disclosure

      @responder                    = @responding_team.responders.first
      @responder_2                  = @responding_team_2.responders.first
      @manager                      = @managing_team.managers.first
      @approver                     = @dacu_disclosure.approvers.first

      @unassigned_case              = create :case, name: 'unassigned'
      @assigned_case                = create :assigned_case,
                                             name: 'assigned R'
      @accepted_case                = create :accepted_case, name: 'accepted R'
      @accepted_case_r2             = create :accepted_case,
                                             responding_team: @responding_team_2,
                                             responder: @responder_2,
                                             name: 'accepted R2'
      @rejected_case                = create :rejected_case, name: 'rejected R'
      @case_with_response           = create :case_with_response, name: 'with response R'
      @responded_case               = create :responded_case, name: 'responded R'
      @closed_case                  = create :closed_case, name: 'closed R'
      @unassigned_sar_case          = create :sar_case, name: 'unassigned SAR'
      @awaiting_responder_sar_case  = create :awaiting_responder_sar,
                                             responding_team: @responding_team,
                                             name: 'SAR awaiting responder'
      @drafting_sar_case            = create :sar_being_drafted,
                                             responding_team: @responding_team,
                                             responder: @responder,
                                             name: 'SAR being drafted'
      @drafting_sar_case_other_team = create :sar_being_drafted,
                                             responding_team: @responding_team_2,
                                             responder: @responder_2,
                                             name: 'SAR being drafted'
      @closed_sar                   = create :closed_sar,
                                             responding_team: @responding_team,
                                             responder: @responder
      @ico_foi_case                 = create :ico_foi_case, original_case: @rejected_case
      @ico_sar_case                 = create :ico_sar_case, original_case: @closed_sar

      @all_cases                    = Case::Base.all
      @existing_foi_cases           = Case::FOI::Standard.all + Case::ICO::FOI.all
      @responder_cases              = Case::Base.all - [@unassigned_sar_case,
                                                        @drafting_sar_case_other_team,
                                                        @ico_sar_case]

      @responder.reload
      @responder_2.reload
      @manager.reload
      @approver.reload
    end

    after(:all)  { DbHousekeeping.clean }

    # This is checked with a test because using Case::Base.descendants on every call might be a little
    # slow, and resolving it using a constant results in an empty array due to class loading issues
    describe 'CASE_TYPES' do
      it 'contains all concrete case types' do
        expect(Case::BasePolicy::Scope::CASE_TYPES)
          .to match_array(Case::Base.descendants.reject { |klass| klass.name.ends_with?('Base') })
      end
    end

    describe '#resolve' do
      context 'managers' do
        it 'returns all cases' do
          manager_scope = Pundit.policy_scope(@manager, Case::Base.all)
          expect(manager_scope).to match_array(@all_cases)
        end
      end

      context 'responders' do
        it 'returns all FOI cases plus SAR cases assigned to their team' do
          responder_scope = Pundit.policy_scope(@responder, Case::Base)
          expect(responder_scope).to match_array(@responder_cases)
        end
      end

      context 'approvers' do
        it 'returns FOI cases and any case assigned to approver/team' do
          approver_scope = described_class.new(@approver, Case::Base.all).resolve
          # ICO Appeals are always trigger, so they get assigned to an approver
          expect(approver_scope).to match_array(
                                      @existing_foi_cases + [@ico_sar_case]
                                    )
        end
      end

      context 'user who is both manager and responder' do
        it 'for responder & manager - returns all cases' do
          @responder.team_roles << TeamsUsersRole.new(team: @dacu_disclosure,
                                                     role: 'manager')
          resolved_scope = described_class.new(@responder, Case::Base.all).resolve
          expect(resolved_scope).to match_array(@all_cases)
        end
      end
    end
  end
end
