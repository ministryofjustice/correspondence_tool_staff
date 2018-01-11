class Case::FOI::Standard < Case::Base

  def self.decorator_class
    Case::FOI::StandardDecorator
  end

  validates :subject_full_name, :subject_type, absence: true
  validates :third_party, exclusion: { in: [true, false], message: 'must be blank' }


end
