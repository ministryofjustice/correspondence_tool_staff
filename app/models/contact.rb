class Contact < ApplicationRecord
  enum contact_type: %i(prison probation solicitor)

  validates :name, presence: true
  validates :address_line_1, presence: true
  validates :postcode, presence: true
  validates :contact_type, presence: true

  def address
    format_address("\n")
  end

  def inline_address
    format_address(", ")
  end

  private

  def format_address(seperator)
    [name,
     address_line_1,
     address_line_2,
     town,
     county,
     postcode].reject(&:empty?).join(seperator)
  end
end
