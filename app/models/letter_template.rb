class LetterTemplate < ApplicationRecord
  validates :name, :abbreviation, :body, :template_type, presence: true
  validates :abbreviation, uniqueness: true

  enum template_type: {
    dispatch: 'dispatch',
    acknowledgement: 'acknowledgement',
  }

  def self.type_name(type)
    LetterTemplate.template_types[type] || 'unknown'
  end

  def render(values)
    template = ERB.new(body)
    template.result(binding)
  end
end
