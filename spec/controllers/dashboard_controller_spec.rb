require "rails_helper"

describe DashboardController do
  let(:admin)         { create :admin }
  let!(:search_query) { create :search_query}
  let!(:filter_query) { create :search_query, :filter }
  let!(:list_query)   { create :search_query, :list}

  describe '#search_queries' do

    before do
      sign_in admin
      get :search_queries
    end
    it 'renders the index view' do
      expect(request.path).to eq('/dashboard/search_queries')
    end

    it 'has search queries' do
      expect(subject.queries).to eq [search_query]
      expect(subject.queries).not_to include list_query
    end
  end

  describe '#list_queries' do

    before do
      sign_in admin
      get :list_queries
    end

    it 'renders the index view' do
      expect(request.path).to eq('/dashboard/list_queries')
    end

    it 'has list queries' do
      expect(subject.queries).to eq [list_query]
      expect(subject.queries).not_to include search_query
    end
  end
end
