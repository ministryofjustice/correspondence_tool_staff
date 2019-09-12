class LetterTemplate < ApplicationRecord
  validates :name, :body, :type, presence: true

  enum type: {
    dispatch: 'dispatch',
    acknowledgement: 'acknowledgement',
  }

  def render(values)
    template = ERB.new(body)
    template.result(binding)
  end
end
