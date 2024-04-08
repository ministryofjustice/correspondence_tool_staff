class Case::ICO::FoiDecorator < Case::ICO::BaseDecorator
  def pretty_type
    "ICO appeal (FOI)"
  end

  def requester_name_and_type
    pretty_type
  end
end
