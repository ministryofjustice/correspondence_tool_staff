require "rails_helper"

describe ContactsSearchService do
  let(:contact) { class_double(Contact) }

  let(:filters) { %w[prison probation] }

  let(:search_term) { "HMP" }

  let(:service_1) do
    described_class.new(
      filters:,
      search_term:,
      contact:,
    )
  end

  let(:service_2) do
    described_class.new(
      filters: [],
      search_term:,
      contact:,
    )
  end

  describe "#call" do
    it "with filters" do
      expect(contact).to receive(:filtered_search_by_contact_name).with(filters, search_term)
      expect(contact).not_to receive(:search_by_contact_name)
      service_1.call
    end

    it "without filters" do
      expect(contact).to receive(:search_by_contact_name).with("HMP")
      expect(contact).not_to receive(:filtered_search_by_contact_name)
      service_2.call
    end
  end
end
