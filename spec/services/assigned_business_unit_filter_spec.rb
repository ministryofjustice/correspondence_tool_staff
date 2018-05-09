require 'rails_helper'

describe 'AssignedBusinessUnitFilter' do

  before(:all) do
    @responding_team_1 = create :responding_team
    @responding_team_2 = create :responding_team
    @responding_team_3 = create :responding_team

    @unassigned_case  = create :case, name: 'Unassigned case'

    @pending_case_1  = create :case, responding_team: @responding_team_1, name: 'pending team 1'
    @pending_case_2  = create :case, responding_team: @responding_team_2, name: 'pending team 2'
    @pending_case_3  = create :case, responding_team: @responding_team_3, name: 'pending team 3'

    @accepted_case_1 = create :accepted_case, responding_team: @responding_team_1, name: 'accepted team 1'
    @accepted_case_2 = create :accepted_case, responding_team: @responding_team_2, name: 'accepted team 2'
    @accepted_case_3 = create :accepted_case, responding_team: @responding_team_3, name: 'accepted team 3'

    @closed_case_1    = create :closed_case, responding_team: @responding_team_1, name: 'closed team 1'
    @closed_case_3    = create :closed_case, responding_team: @responding_team_3, name: 'closed team 3'

    @rejected_case_2  = create :rejected_case, responding_team: @responding_team_2, name: 'rejected_team 1'
    @rejected_case_3  = create :rejected_case, responding_team: @responding_team_2, name: 'rejected team 3 '
  end

  after(:all) { DbHousekeeping.clean }

  describe '#call' do

    let(:arel)          { Case::Base.all }
    let(:search_query)  { create :search_query, filter_assigned_to_ids: [@responding_team_1.id, @responding_team_2.id] }
    let(:filter)        { AssignedBusinessUnitFilter.new(search_query, arel) }

    it 'filters only those cases that have assignments to specified business units' do
      expected_results =  [
          @pending_case_1,
          @pending_case_2,
          @accepted_case_1,
          @accepted_case_2,
          @closed_case_1
      ]
      expect(filter.call).to match_array expected_results
    end

    it 'returns an arel' do
      expect(filter.call).to be_instance_of(Case::Base::ActiveRecord_Relation)
    end
  end



end
