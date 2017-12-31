class Case::FOI < Case::Base

  def self.decorator_class
    Case::FOIDecorator
  end

  validates :subject_full_name, :subject_type, absence: true
  validates :third_party, exclusion: { in: [true, false], message: 'must be blank' }


end
