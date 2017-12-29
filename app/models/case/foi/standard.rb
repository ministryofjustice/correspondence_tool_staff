class Case::FOI::Standard < Case::Base
  class << self
    def decorator_class
      Case::FOI::StandardDecorator
    end

    def type_abbreviation
      'FOI'
    end
  end


  validates :subject_full_name, :subject_type, absence: true
  validates :third_party, exclusion: { in: [true, false], message: 'must be blank' }


end
