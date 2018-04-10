# == Schema Information
#
# Table name: search_queries
#
#  id               :integer          not null, primary key
#  query_hash       :string           not null
#  user_id          :integer          not null
#  query            :string           not null
#  num_results      :integer          not null
#  num_clicks       :integer          default(0), not null
#  highest_position :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

describe SearchQuery do

  describe '.create_from_search_service' do

    let(:params)      { { query: 'cats and dogs', page: 2  } }
    let(:user)        { double User, id: 1234 }
    let(:service)     { CaseSearchService.new(user, params) }
    let(:query_hash)  { Digest::SHA256.hexdigest "1234:2018-04-11:cats and dogs" }

    context 'no record with same query hash exists' do
      it 'writes a search_query_record' do
        Timecop.freeze(Time.new(2018, 4, 11, 12, 33, 22)) do
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
        SearchQuery.create(
                       query_hash:        query_hash,
                       user_id:           user.id,
                       query:             'cats and dogs',
                       num_results:       22,
                       num_clicks:        5,
                       highest_position:  3)

        expect {
          SearchQuery.create_from_search_service(service)
        }.not_to change { SearchQuery.count }

      end
    end
  end

  describe '.update_for_click' do
    let(:position) { 3 }
    let(:hash)             { 'XYZ' }
    let(:params)           { { hash: hash, pos: position } }

    context 'user clicks for the first time' do
      let!(:record)      { create :search_query }

      it 'records the click' do
        SearchQuery.update_for_click(params)
        record.reload
        expect(record.num_clicks).to eq 1
      end

      it 'updates the highest position' do
        SearchQuery.update_for_click(params)
        record.reload
        expect(record.highest_position).to eq position
      end
    end

    context 'user clicks on higher option' do
      let!(:record)          { create :search_query, :clicked }
      let(:position) { 1 }
      
      it 'records the click' do
        SearchQuery.update_for_click(params)
        record.reload
        expect(record.num_clicks).to eq 2
      end

      it 'updates the highest position' do
        SearchQuery.update_for_click(params)
        record.reload
        expect(record.highest_position).to eq position
      end
    end

    context 'user clicks on a lower position' do
      let!(:record)          { create :search_query, :clicked }
      let(:position)         { 33 }

      it 'records the click' do
        SearchQuery.update_for_click(params)
        record.reload
        expect(record.num_clicks).to eq 2
      end

      it 'does not update the highest position' do
        SearchQuery.update_for_click(params)
        record.reload
        expect(record.highest_position).to eq 3
      end
    end
  end
end
