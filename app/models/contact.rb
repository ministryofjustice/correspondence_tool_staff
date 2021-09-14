class Contact < ApplicationRecord
  belongs_to :contact_type, class_name: 'CategoryReference'

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
