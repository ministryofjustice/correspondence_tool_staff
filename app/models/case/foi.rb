class Case::FOI < Case

  validates absence_of(:subject_full_name, :subject_type, :third_party)

end
