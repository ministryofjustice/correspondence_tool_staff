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
    context 'no assigned teams selected' do
      let(:arel)          { Case::Base.all }
      let(:search_query)  { create :search_query, filter_assigned_to_ids: [] }
      let(:filter)        { AssignedBusinessUnitFilter.new(search_query, arel) }

      it 'returns all cases' do
        expected_results =  [
          @unassigned_case,
          @pending_case_1,
          @pending_case_2,
          @pending_case_3,
          @accepted_case_1,
          @accepted_case_2,
          @accepted_case_3,
          @closed_case_1,
          @closed_case_3,
          @rejected_case_2,
          @rejected_case_3
        ]
        expect(filter.call).to match_array expected_results
      end
    end

    context 'multiple assigned teams selected' do
      let(:arel)          { Case::Base.all }
      let(:search_query)  { create :search_query, filter_assigned_to_ids: [@responding_team_1.id, @responding_team_2.id] }
      let(:filter)        { AssignedBusinessUnitFilter.new(search_query, arel) }

      describe '#call' do
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
  end

  describe '#responding_business_units' do

    it 'returns all business units' do
      expect(AssignedBusinessUnitFilter.responding_business_units)
          .to match_array BusinessUnit.active.responding.order(:name)
    end

  end

  describe '#crumbs' do
    let(:arel)          { Case::Base.all }
    let(:filter)        { AssignedBusinessUnitFilter.new(search_query, arel) }

    context 'no assigned teams selected' do
      let(:search_query)  { create :search_query, filter_assigned_to_ids: [] }

      it 'returns no crumbs' do
        expect(filter.crumbs).to be_empty
      end
    end

    context 'a single assigned team selected' do
      let(:search_query)  { create :search_query, filter_assigned_to_ids: [@responding_team_1.id] }

      it 'returns a single crumb' do
        expect(filter.crumbs).to have(1).items
      end

      it 'uses the name of the assigned team as the crumb text' do
        expect(filter.crumbs[0].first).to eq @responding_team_1.name
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { filter.crumbs[0].second }

        it 'remove the assigned teams filter' do
          expect(subject).to include 'filter_assigned_to_ids' => ['']
        end

        it 'leaves the other attributes untouched' do
          expect(subject).to include(
                               'search_text'            => 'Winnie the Pooh',
                               'common_exemption_ids'   => [],
                               'exemption_ids'          => [],
                               'filter_case_type'       => [],
                               'filter_sensitivity'     => [],
                               'filter_status'          => [],
                               'parent_id'              => search_query.id
                             )
        end
      end
    end

    context 'multiple assigned teams selected' do
      let(:search_query)  { create :search_query, filter_assigned_to_ids: [
                                                    @responding_team_1.id,
                                                    @responding_team_1.id
                                                  ] }

      it 'returns a single crumb' do
        expect(filter.crumbs).to have(1).items
      end

      it 'uses the name of the assigned team + 1 more as the crumb text' do
        expect(filter.crumbs[0].first).to eq "#{@responding_team_1.name} + 1 more"
      end
    end
  end
end
