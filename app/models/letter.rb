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
    @letter_template = LetterTemplate.find_by(id: letter_template_id)
  end

  def body
    @letter_template&.render(values, self, 'body')
  end
  
  def values
    cloned_case = @case.dup

    attributes = %w[
      prison_number
      recipient
      request_dated
      subject_address
      subject_full_name
      third_party_company_name
      third_party_name
    ]

    attributes.each do |attr|
      cloned_case.assign_attributes({attr.to_sym => ERB::Util.html_escape(@case.send(attr)) })
    end
    cloned_case
  end

  def letter_date
    Date.today.strftime('%e %B %Y')
  end

  def template_name
    @letter_template&.name
  end

  def name
    case @letter_template.template_type
    when "dispatch"
      values.recipient_name
    when "acknowledgement"
      values.requester_name
    end
  end

  def address
    case @letter_template.template_type
    when "dispatch"
      format_address(values.recipient_address)
    when "acknowledgement"
      format_address(values.requester_address)
    end
  end

  def letter_address
    @letter_template&.render(values, self, 'letter_address')
  end

  def company_name
    values.third_party_company_name.presence
  end

  def format_address(address)
    if address.include?(",")
      address.split(',').map {|word| word.strip }.join("\n") 
    else
      address
    end
  end
end
