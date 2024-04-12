class Contact < ApplicationRecord
  validates :name, presence: true
  validates :address_line_1, presence: true
  validates :postcode, presence: true
  validates :contact_type, presence: true
  validate :validate_emails

  attr_readonly :contact_type_id

  belongs_to :contact_type, class_name: "CategoryReference", inverse_of: :contacts

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
    filter_sql = "category_references.code IN (?)"
    joins(:contact_type).where(filter_sql, filters)
  end

  def self.search_by_contact_name(search_term)
    search_sql = "LOWER(name) LIKE CONCAT('%', ?, '%')"
    where(search_sql, search_term).order(:name)
  end

  def self.filtered_search_by_contact_name(filters, search_term)
    filter_by_contact_type(filters).search_by_contact_name(search_term)
  end

  def all_emails
    data_request_emails&.split("\n")
  end

private

  def format_address(separator)
    [
      address_line_1,
      address_line_2,
      town,
      county,
      postcode,
    ].compact
     .reject(&:empty?)
     .join(separator)
  end

  def validate_emails
    return if data_request_emails.blank?

    data_request_emails.split.each do |email|
      next if email =~ /\A([^@,]+)@([^@,]+)\z/ # regex disallows commas and additional @s

      errors.add(
        :data_request_emails,
        :invalid,
      )
    end
  end
end
