class LetterTemplate < ApplicationRecord
  validates :name, :body, :template_type, presence: true

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
