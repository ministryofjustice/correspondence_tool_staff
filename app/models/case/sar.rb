class Case::SAR < Case

  validates :subject_full_name, :subject_type, :third_party, presence: true

end
