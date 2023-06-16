class ContactsSearchService
  def initialize(filters: "", search_term: "", contact: Contact)
    @contact = contact
    @filters = filters
    @search_term = search_term
  end

  def call
    if filters_present?
      @contact.filtered_search_by_contact_name(@filters, @search_term)
    else
      @contact.search_by_contact_name(@search_term)
    end
  end

private

  def filters_present?
    @filters&.any?
  end
end
