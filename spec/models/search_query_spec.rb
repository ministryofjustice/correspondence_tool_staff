require 'rails_helper'

describe SearchQuery do

  describe '.create_from_search_service' do
    let(:uuid)        { '0424c55f-db7b-41cf-973d-a5fbb01f8743' }
    let(:query)       { 'dogs and cats' }
    let(:result_set)  { %w( cat mouse horse) }
    let(:service)   { double CaseSearchService, uuid: uuid, query: query, result_set: result_set }

    it 'writes a search_query_record' do
      SearchQuery.create_from_search_service(service)
      sq = SearchQuery.first
      expect(sq.uuid).to eq uuid
      expect(sq.query).to eq query
      expect(sq.num_results).to eq result_set.size
      expect(sq.num_clicks).to eq 0
    end
  end
end
