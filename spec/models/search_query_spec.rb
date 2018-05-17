# == Schema Information
#
# Table name: search_queries
#
#  id               :integer          not null, primary key
#  user_id          :integer          not null
#  query            :jsonb            not null
#  num_results      :integer          not null
#  num_clicks       :integer          default(0), not null
#  highest_position :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  parent_id        :integer
#  query_type       :enum             default("search"), not null
#  filter_type      :string
#

require 'rails_helper'

describe SearchQuery do

  describe 'tree functions' do

    before(:each) do
      @root             = create :search_query, search_text: 'root'


      @child            = create :search_query, :filter,
                                 parent_id: @root.id,
                                 filter_case_type: ['foi-standard']
      @child_2          = create :search_query, :filter,
                                 parent_id: @root.id,
                                 filter_case_type: ['foi-ir-compliance']
    end

    describe 'root' do
      it 'find the top-most ancestor' do
        expect(@child.root).to eq @root
      end
    end

    describe 'ancestors' do
      context 'a child node' do
        it 'returns an array of ancestors, root last' do
          expect(@child.ancestors).to eq( [ @root ] )
        end
      end

      context 'the root node' do
        it 'returns and empty array' do
          expect(@root.ancestors).to be_empty
        end
      end
    end

    describe '.descendents' do
      it 'returns and array of descendents, oldest child first' do
        expect(@root.descendants).to eq( [ @child, @child_2 ] )
      end
    end
  end

  describe 'self.filter_attributes' do
    it 'returns all the filter attributes' do
      expect(SearchQuery.filter_attributes).to match_array [
                                                 :common_exemption_ids,
                                                 :exemption_ids,
                                                 :external_deadline_from,
                                                 :external_deadline_to,
                                                 :filter_assigned_to_ids,
                                                 :filter_case_type,
                                                 :filter_open_case_status,
                                                 :filter_sensitivity,
                                                 :filter_status,
                                                 :filter_timeliness,
                                               ]
    end
  end

  describe 'self.query_attributes' do
    it 'returns all the query attributes' do
      expect(SearchQuery.query_attributes).to match_array [
                                                :search_text,
                                                :list_path,
                                                :list_params,
                                                :common_exemption_ids,
                                                :exemption_ids,
                                                :external_deadline_from,
                                                :external_deadline_to,
                                                :filter_assigned_to_ids,
                                                :filter_case_type,
                                                :filter_open_case_status,
                                                :filter_sensitivity,
                                                :filter_status,
                                                :filter_timeliness,
                                              ]
    end
  end

  describe '#update_for_click' do

    context 'user clicks for the first time' do
      let(:search_query) { create :search_query }
      let(:position)     { 3 }

      it 'records the click' do
        search_query.update_for_click(position)
        expect(search_query.num_clicks).to eq 1
      end

      it 'updates the highest position' do
        new_highest_position = 2
        search_query.update_for_click(new_highest_position)
        expect(search_query.highest_position).to eq new_highest_position
      end
    end

    context 'user clicks on higher option' do
      let(:search_query) { create :search_query, :clicked }
      let(:position)     { 1 }

      it 'records the click' do
        search_query.update_for_click(position)
        expect(search_query.num_clicks).to eq 2
      end

      it 'updates the highest position' do
        search_query.update_for_click(position)
        search_query.reload
        expect(search_query.highest_position).to eq position
      end
    end

    context 'user clicks on a lower position' do
      let(:search_query) { create :search_query, :clicked }
      let(:position)     { 33 }

      it 'records the click' do
        search_query.update_for_click(position)
        expect(search_query.num_clicks).to eq 2
      end

      it 'does not update the highest position' do
        search_query.update_for_click(position)
        expect(search_query.highest_position).to eq 3
      end
    end

  end

  describe '.record_list' do
    let(:user)    { create :manager }
    let(:params)  { ActiveSupport::HashWithIndifferentAccess.new(action: 'open_cases', tab: 'in_time') }

    it 'writes a record with query_type of list' do
      rec = SearchQuery.record_list(user, '/open_cases', params)
      expect(rec.user_id).to eq user.id
      expect(rec.list_path).to eq '/open_cases'
      expect(YAML.load(rec.list_params)).to eq params
    end
  end

  describe '#results' do
    before :all do
      @setup = StandardSetup.new(only_cases: [
                                   :std_draft_foi,
                                   :std_draft_foi_late,
                                   :trig_draft_foi,
                                   :std_draft_irt,
                                   :std_closed_foi,
                                 ])
      Case::Base.update_all_indexes
    end

    after :all do
      DbHousekeeping.clean
    end

    # let!(:case_standard)      { create :accepted_case,
    #                                    :indexed,
    #                                    subject: 'Winnie the Pooh' }
    # let!(:case_trigger)       { create :accepted_case,
    #                                    :flagged,
    #                                    :indexed,
    #                                    subject: 'Tigger the tiger' }
    # let!(:case_ir_compliance) { create :compliance_review,
    #                                    :indexed,
    #                                    subject: 'Gruffalo' }
    # let!(:case_closed)        { create :closed_case,
    #                                    :indexed,
    #                                    subject: 'Super Worm' }
    let(:user)    { create :manager }

    describe 'results from using a filter' do
      it 'returns the result of searching for search_text' do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: 'std_draft_foi'
        expect(search_query.results).to eq [@setup.std_draft_foi,
                                            @setup.std_draft_foi_late]
      end

      it 'returns the result of filtering for sensitivity' do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: 'draft',
                              filter_sensitivity: ['trigger']
        expect(search_query.results).to eq [@setup.trig_draft_foi]
      end

      it 'returns the result of filtering for type' do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: 'draft',
                              filter_case_type: ['foi-ir-timeliness']
        expect(search_query.results).to eq [@setup.std_draft_irt]
      end

      it 'returns the result of filtering by status' do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: 'std',
                              filter_status: ['closed']
        expect(search_query.results).to eq [@setup.std_closed_foi]
      end

      it 'returns the result of filtering by timeliness' do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: 'draft',
                              filter_timeliness: ['late']
        expect(search_query.results).to eq [@setup.std_draft_foi_late]
      end
    end

    context 'case listing' do
      it 'uses the list of cases if provided' do
        cases_list = Case::Base.where(id: [@setup.std_draft_foi.id,
                                           @setup.std_draft_irt.id])

        search_query = create :search_query, :list,
                              user_id: user.id,
                              filter_case_type: ['foi-standard']
        expect(search_query.results(cases_list)).to eq [@setup.std_draft_foi]
      end
    end

    context 'no list of cases provided' do
      it 'uses the list of cases if provided' do
        search_query = create :search_query, :list,
                              user_id: user.id,
                              filter_case_type: ['foi-standard']
        expect { search_query.results }.to raise_error(ArgumentError)
      end

    end
  end

  describe '#params_without_filters' do
    it 'returns all the filter attributes' do
      search_query = create :search_query

      expect(search_query.params_without_filters)
        .to eq({ 'search_text' => 'Winnie the Pooh',
                 'list_params' => '',
                 'list_path'   => '', })
    end
  end

  describe '#applied_filters' do
    it 'includes case type filters' do
      search_query = create :search_query, filter_case_type: ['foi-standard']
      expect(search_query.applied_filters).to eq [CaseTypeFilter]
    end

    it 'includes status filters' do
      search_query = create :search_query, filter_status: ['closed']
      expect(search_query.applied_filters).to eq [CaseStatusFilter]
    end

    it 'includes assigned business unit filters' do
      search_query = create :search_query, filter_assigned_to_ids: [1]
      expect(search_query.applied_filters).to eq [AssignedBusinessUnitFilter]
    end

    it 'includes exemption filters' do
      search_query = create :search_query, exemption_ids: [2]
      expect(search_query.applied_filters).to eq [ExemptionFilter]
    end

    it 'includes external deadline filters' do
      search_query = create :search_query,
                            external_deadline_from: Date.today,
                            external_deadline_to: Date.today
      expect(search_query.applied_filters).to eq [ExternalDeadlineFilter]
    end

    it 'includes timeliness filters' do
      search_query = create :search_query, filter_timeliness: ['in_time']
      expect(search_query.applied_filters).to eq [TimelinessFilter]
    end
  end
end
