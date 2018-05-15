require "rails_helper"

describe DashboardController do
  let(:admin)         { create :admin }
  let!(:search_query) { create :search_query}

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
    end
  end
end
