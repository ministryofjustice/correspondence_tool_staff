class Case::ICO::SARDecorator < Case::ICO::BaseDecorator
  def pretty_type
    "ICO appeal (SAR)"
  end

  def requester_name_and_type
    pretty_type
  end

  def time_taken
    calendar_days_taken
  end
end
