require 'rails_helper'


describe Case::BasePolicy::Scope do

  describe 'case scope policy' do

    before(:all) do
      @responding_team        = create :responding_team
      @responding_team_2      = create :responding_team
      @managing_team          = find_or_create :team_dacu
      @dacu_disclosure        = find_or_create :team_dacu_disclosure

      @responder              = @responding_team.responders.first
      @responder_2            = @responding_team_2.responders.first
      @manager                = @managing_team.managers.first
      @approver               = @dacu_disclosure.approvers.first

      @unassigned_case        = create :case, name: 'unassigned'
      @assigned_case          = create :assigned_case,
                                       responding_team: @responding_team, name: 'assigned R'
      @accepted_case          = create :accepted_case,
                                       responder: @responder,
                                       manager: @manager, name: 'accepted R'
      @accepted_case_r2       = create :accepted_case,
                                       responder: @responder_2,
                                       name: 'acceptd R2'
      @rejected_case          = create :rejected_case,
                                       responding_team: @responding_team,  name: 'rejected R'
      @case_with_response     = create :case_with_response,
                                       responder: @responder, name: 'with response R'
      @responded_case         = create :responded_case,
                                       responder: @responder, name: 'responded R'
      @closed_case            = create :closed_case,
                                       responder: @responder, name: 'closed R'
      @existing_cases         = Case::Base.all
      @responder_cases        = Case::Base.all - [@unassigned_case, @accepted_case_r2, @rejected_case]
    end

    after(:all)  { DbHousekeeping.clean }

    context 'scope with no restrictions' do
      it 'for managers - returns all cases' do
        manager_scope = described_class.new(@manager, Case::Base.all).resolve
        expect(manager_scope).to match_array(@existing_cases)
      end

      it 'for responders - returns only cases assigned to their team' do
        responder_scope = described_class.new(@responder, Case::Base.all).resolve
        expect(responder_scope).to match_array(@responder_cases)
      end

      it 'for approvers - returns all cases' do
        approver_scope = described_class.new(@approver, Case::Base.all).resolve
        expect(approver_scope).to match_array(@existing_cases)
      end

      it 'for responder & manager - returns all cases' do
        @responder.team_roles << TeamsUsersRole.new(team: @dacu_disclosure,
                                                   role: 'manager')
        resolved_scope = described_class.new(@responder, Case::Base.all).resolve
        expect(resolved_scope).to match_array(@existing_cases)
      end
    end

    context '#for_view_only' do
      it 'returns all cases for managers' do
        manager_scope = described_class.new(@manager, Case::Base.all).for_view_only
        expect(manager_scope).to match_array(@existing_cases)
      end

      it 'for responders - returns all cases' do
        responder_scope = described_class.new(@responder, Case::Base.all).for_view_only
        expect(responder_scope).to match_array(@existing_cases)
      end

      it 'for approvers - returns all cases' do
        approver_scope = described_class.new(@approver, Case::Base.all).for_view_only
        expect(approver_scope).to match_array(@existing_cases)
      end

      it 'for responder & manager - returns all cases' do
        @responder.team_roles << TeamsUsersRole.new(team: @dacu_disclosure,
                                                    role: 'manager')
        resolved_scope = described_class.new(@responder, Case::Base.all).for_view_only
        expect(resolved_scope).to match_array(@existing_cases)
      end
    end

  end
end
