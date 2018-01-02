class Case::FOI < Case

  validates :subject_full_name, :subject_type, absence: true
  validates :third_party, exclusion: { in: [true, false], message: 'must be blank' }
end
