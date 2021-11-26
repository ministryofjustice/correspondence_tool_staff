class Case::SAR::InternalReview < Case::SAR::Standard

  include LinkableOriginalCase

  validates_presence_of :original_case

  attr_accessor :original_case_number

  class << self
    def type_abbreviation
      # This string is used when constructing paths or methods in other parts of
      # the system. Ensure that it does not come from a user-supplied parameter,
      # and does not contain special chars like slashes, etc.
      'SAR_INTERNAL_REVIEW'
    end

    def state_machine_name
      'sar'
    end
  end
end
