class Case::ICO::FOIDecorator < Case::ICO::BaseDecorator

  def pretty_type
    'ICO appeal (FOI)'
  end

  def requester_name_and_type
    pretty_type
  end

  def original_internal_deadline
    if object.original_internal_deadline.present?
      I18n.l(object.original_internal_deadline, format: :default)
    end
  end

  def original_external_deadline
    if object.original_external_deadline.present?
      I18n.l(object.original_external_deadline, format: :default)
    end
  end

  def original_date_responded
    if object.original_date_responded.present?
      I18n.l(object.original_date_responded, format: :default)
    end
  end

end
