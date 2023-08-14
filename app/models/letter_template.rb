class LetterTemplate < ApplicationRecord
  validates :name, :abbreviation, :body, :template_type, presence: true
  validates :abbreviation, uniqueness: true

  DISPATCH_LETTER_TEL_NUM = "01283 496 110".freeze
  ACKNOWLEDGEMENT_LETTER_TEL_NUM = "01283 496 136".freeze

  enum template_type: {
    dispatch: "dispatch",
    acknowledgement: "acknowledgement",
  }

  def self.type_name(type)
    LetterTemplate.template_types[type] || "unknown"
  end

  def render(values, letter, field)
    template = ERB.new(send(field))
    template.result(binding)
  end

  def telephone_number
    case template_type
    when "dispatch"
      DISPATCH_LETTER_TEL_NUM
    when "acknowledgement"
      ACKNOWLEDGEMENT_LETTER_TEL_NUM
    end
  end
end
