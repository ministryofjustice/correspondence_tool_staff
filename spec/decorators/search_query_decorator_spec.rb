require "rails_helper"

describe SearchQueryDecorator, type: :model do
  context "when search_query" do
    let(:manager) { create(:manager) }
    let(:query) { create(:search_query, user_id: manager.id) }
    let(:decorated_query) { described_class.decorate(query) }

    it "displays the user roles" do
      expect(decorated_query.user_roles).to eq "manager"
    end

    it "displays the query details" do
      expect(decorated_query.search_query_details).to eq "Search text: Winnie the Pooh"
    end
  end

  context "when simple list_query" do
    let(:query) { create(:search_query, :simple_list) }
    let(:decorated_query) { described_class.decorate(query) }

    it "displays the query details" do
      expect(decorated_query.list_query_details).to eq " cases open"
    end
  end

  context "when filtered list_query" do
    let(:query) { create(:search_query, :filtered_list) }
    let(:decorated_query) { described_class.decorate(query) }

    it "displays the query details" do
      expect(decorated_query.filtered_list_query_details).to eq "Filter case type: FOI-ir-compliance"
    end
  end
end
