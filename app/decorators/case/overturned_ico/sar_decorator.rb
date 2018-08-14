class Case::OverturnedICO::SARDecorator < Case::BaseDecorator

  def original_case_description
    "ICO appeal (SAR) #{object.original_ico_appeal.number}"
  end

  def type_abbreviation
    # This string is used when constructing paths or methods in other parts of
    # the system. Ensure that it does not come from a user-supplied parameter,
    # and does not contain special chars like slashes, etc.
    'Overturned SAR'
  end

end
