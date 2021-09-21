require "rails_helper"

describe ContactsSearchService do

  let(:contact) { class_double(Contact) }

  let(:filters) { [ "prison","probation" ] }

  let(:search_term) { 'HMP' }

  let(:service_1) { 
    ContactsSearchService.new(
      filters: filters, 
      search_term: search_term, 
      contact: contact
    ) 
  }

  let(:service_2) { 
    ContactsSearchService.new(
      filters: [], 
      search_term: search_term, 
      contact: contact
    ) 
  }

  context '#call' do
    it 'with filters' do
      expect(contact).to receive(:filtered_search_by_contact_name).with(filters, search_term)
      expect(contact).not_to receive(:search_by_contact_name)
      service_1.call
    end
    it 'without filters' do
      expect(contact).to receive(:search_by_contact_name).with("HMP")
      expect(contact).not_to receive(:filtered_search_by_contact_name)
      service_2.call
    end
  end
end
