class Case::ICO::FOIDecorator < Case::BaseDecorator

  def pretty_type
    'ICO appeal for FOI case'
  end

  def requester_name_and_type
    pretty_type
  end

end
