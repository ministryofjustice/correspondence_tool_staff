class LetterTemplate < ApplicationRecord
  validates :name, :body, :template_type, presence: true

  enum template_type: {
    dispatch: 'dispatch',
    acknowledgement: 'acknowledgement',
  }

  def render(values)
    template = ERB.new(body)
    template.result(binding)
  end
end
