class Case::OverturnedIco::FoiDecorator < Case::OverturnedIco::BaseDecorator
  def pretty_type
    "ICO overturned (FOI)"
  end

  def requester_name_and_type
    pretty_type
  end
end
