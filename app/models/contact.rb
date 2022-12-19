class Contact < ApplicationRecord

  validates :name, presence: true
  validates :address_line_1, presence: true
  validates :postcode, presence: true
  validates :contact_type, presence: true

  belongs_to :contact_type, class_name: 'CategoryReference', inverse_of: :contacts

  def address
    format_address("\n")
  end

  def inline_address
    format_address(", ")
  end

  def contact_type_display_value
    contact_type.value
  end

  def self.filter_by_contact_type(filters)
    filter_sql = 'category_references.code IN (?)'
    joins(:contact_type).where(filter_sql, filters)
  end

  def self.search_by_contact_name(search_term)
    search_sql = "LOWER(name) LIKE CONCAT('%', ?, '%')"
    where(search_sql, search_term).order(:name)
  end

  def self.filtered_search_by_contact_name(filters, search_term)
    filter_by_contact_type(filters).search_by_contact_name(search_term)
  end

  private

  def format_address(separator)
    [
      address_line_1,
      address_line_2,
      town,
      county,
      postcode
    ].compact
     .reject(&:empty?)
     .join(separator)
  end
end
