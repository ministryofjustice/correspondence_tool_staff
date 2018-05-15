require 'rails_helper'

describe SearchQueryDecorator, type: :model do

  context 'search_query' do

    let(:manager) { create(:manager) }
    let(:query) { create(:search_query, user_id: manager.id) }
    let(:decorated_query) { SearchQueryDecorator.decorate(query) }

    it 'should display the user roles' do
      expect(decorated_query.user_roles).to eq 'manager'
    end

    it 'should display the user name' do
      expect(decorated_query.user_name).to eq manager.full_name
    end

    it 'should display the query details' do
      expect(decorated_query.search_query_details).to eq 'Search text: Winnie the Pooh'
    end
  end

  context 'list_query' do

    let(:query) { create(:search_query, :list) }
    let(:decorated_query) { SearchQueryDecorator.decorate(query) }

    it 'should display the query details' do
      expect(decorated_query.list_query_details).to eq '/cases/open/in_time'
    end
  end

  context 'list_query' do

    let(:query) { create(:search_query, :filtered_list) }
    let(:decorated_query) { SearchQueryDecorator.decorate(query) }

    it 'should display the query details' do
      expect(decorated_query.filtered_list_query_details).to eq 'Filter case type: Foi-ir-compliance'
    end
  end
end
