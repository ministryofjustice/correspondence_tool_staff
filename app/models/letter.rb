class Letter
  # Letters are transient structures used to drive Rails' `form_for`
  # and shortly to contain logic for supporting intelligent letter templates
  # (e.g. the ability for a subsequent instance of a letter to
  #  calculate the date its predecessor was sent)
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  attr_accessor :letter_template_id

  def initialize(letter_template_id, kase = nil)
    @letter_template_id = letter_template_id
    @case = kase
    @letter_template = LetterTemplate.find_by_id(letter_template_id)
  end

  def body
    @letter_template&.render(@case)
  end

  def values
    @case
  end

  def letter_date
    Date.today.strftime('%e %b %Y')
  end

  def template_name
    @letter_template&.name
  end
end

