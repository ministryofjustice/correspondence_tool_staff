# == Schema Information
#
# Table name: search_queries
#
#  id               :integer          not null, primary key
#  user_id          :integer          not null
#  parent_id        :integer
#  query_type       :enum             default("search"), not null
#  filter_type      :string
#  query            :string           not null
#  query_hash       :string           not null
#  num_results      :integer          not null
#  num_clicks       :integer          default(0), not null
#  highest_position :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

describe SearchQuery do

  describe 'tree functions' do

    before(:each) do
      @root             = create :search_query,
                                 query_hash: 'ROOTX'
      @child            = create :search_query, :filter,
                                 query_hash: 'CHILD',
                                 parent_id: @root.id,
                                 query: 'type:foi-std'
      @child_2          = create :search_query, :filter,
                                 parent_id: @root.id,
                                 query_hash: 'CHILD-2',
                                 query: 'type:foi-irc'
      @grandchild       = create :search_query, :filter,
                                 parent_id: @child.id,
                                 query_hash: 'GRAND-CHILD',
                                 query: 'status:closed'
      @greatgrandchild  = create :search_query, :filter,
                                 parent_id: @grandchild.id,
                                 query_hash: 'GREAT-GRAND-CHILD',
                                 query: 'date:20180101-20180331'
    end

    describe 'root' do
      it 'find the top-most ancestor' do
        expect(@greatgrandchild.root).to eq @root
      end
    end

    describe 'ancestors' do
      context 'a child node' do
        it 'returns an array of ancestors, root last' do
          expect(@greatgrandchild.ancestors).to eq( [ @grandchild, @child, @root ] )
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
        expect(@root.descendants).to eq( [ @child, @child_2, @grandchild, @greatgrandchild ] )
      end
    end

    describe '.by_query_hash!' do
      it 'finds the record with the specified query_hash' do
        expect(SearchQuery.by_query_hash!('CHILD-2')).to eq @child_2
      end
    end

    describe '.by_query_hash_with_ancestors!' do
      it 'returns a collection of all ancestors including the specified record starting at the root' do
        expected = [ @root, @child, @grandchild, @greatgrandchild ]
        expect(SearchQuery.by_query_hash_with_ancestors!('GREAT-GRAND-CHILD')).to eq expected
      end
    end
  end



  describe '.create_from_search_service' do

    let(:params)      { { query: 'cats and dogs', page: 2  } }
    let(:user)        { create :manager }
    let(:service)     { CaseSearchService.new(user, params) }
    let(:time)        { Time.new(2018, 4, 11, 12, 33, 22) }
    let(:query_hash)  { CaseSearchService.generate_query_hash(user, 'search', nil, 'cats and dogs', time) }

    context 'no record with same query hash exists' do
      it 'writes a search_query_record' do
        Timecop.freeze(time) do
          allow(service).to receive(:unpaginated_result_set).and_return(double "result_set", size: 22)
          expect {
            SearchQuery.create_from_search_service(service)
          }.to change { SearchQuery.count }.by(1)
          sq = SearchQuery.first
          expect(sq.query_hash).to eq query_hash
          expect(sq.query).to eq params[:query]
          expect(sq.num_results).to eq 22
          expect(sq.num_clicks).to eq 0
        end
      end
    end

    context 'record with same query hash already exists' do
      it 'does not create a new record' do
        Timecop.freeze(Time.new(2018, 4, 11, 12, 33, 22)) do
          SearchQuery.create(
                         query_hash:        query_hash,
                         user_id:           user.id,
                         query:             'cats and dogs',
                         query_type:        'search',
                         num_results:       22,
                         num_clicks:        5,
                         highest_position:  3)
          allow(service).to receive(:unpaginated_result_set).and_return(double "result_set", size: 22)
          allow(service).to receive(:query_hash).and_return(query_hash)
          expect {
            SearchQuery.create_from_search_service(service)
          }.not_to change { SearchQuery.count }
        end
      end
    end
  end

  describe '.update_for_click' do
    let(:position)          { 3 }
    let(:query_hash)        { 'XYZ' }
    let(:params)            { { hash: query_hash, pos: position } }

    context 'the query hash is in the flash' do

      let(:flash)          { { query_hash: 'XYZ' } }

      context 'user clicks for the first time' do
        let!(:record)      { create :search_query, query_hash: query_hash }

        it 'records the click' do
          SearchQuery.update_for_click(query_hash, position)
          record.reload
          expect(record.num_clicks).to eq 1
        end

        it 'updates the highest position' do
          new_highest_position = 2
          SearchQuery.update_for_click(query_hash, new_highest_position)
          record.reload
          expect(record.highest_position).to eq new_highest_position
        end
      end

      context 'user clicks on higher option' do
        let!(:record)          { create :search_query, :clicked, query_hash: query_hash }
        let(:position) { 1 }

        it 'records the click' do
          SearchQuery.update_for_click(query_hash, position)
          record.reload
          expect(record.num_clicks).to eq 2
        end

        it 'updates the highest position' do
          SearchQuery.update_for_click(query_hash, position)
          record.reload
          expect(record.highest_position).to eq position
        end
      end

      context 'user clicks on a lower position' do
        let(:query_hash)        { 'xxxx' }
        let!(:record)           { create :search_query, :clicked, query_hash: query_hash }
        let(:position)          { 33 }

        it 'records the click' do
          SearchQuery.update_for_click(query_hash, position)
          record.reload
          expect(record.num_clicks).to eq 2
        end

        it 'does not update the highest position' do
          SearchQuery.update_for_click(query_hash, position)
          record.reload
          expect(record.highest_position).to eq 3
        end
      end
    end

  end
end
