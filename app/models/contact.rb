class Contact < ApplicationRecord
  validates :name, presence: true
  validates :address_line_1, presence: true
  validates :postcode, presence: true
  validates :contact_type, presence: true
  validate :validate_contact_type

  attr_accessor :contact_type_display_value


  def address
    format_address("\n")
  end

  def inline_address
    format_address(", ")
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

  def validate_contact_type
    address_type_codes = CategoryReference.list_by_category(:contact_type).map do |category| 
      category.code
    end

    unless address_type_codes.include?(contact_type)
      errors[:contact_type] << "Unacceptable contact type"
    end
  end
end
