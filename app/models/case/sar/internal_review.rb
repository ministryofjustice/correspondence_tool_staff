class Case::SAR::InternalReview < Case::SAR::Standard

  include LinkableOriginalCase

  validates_presence_of :original_case

  attr_accessor :original_case_number

  validates_presence_of :sar_ir_subtype

  jsonb_accessor :properties,
                 sar_ir_subtype: :string

  HUMANIZED_ATTRIBUTES = {
    sar_ir_subtype: 'Case type',
    subject: 'Case summary',
    message: 'Full case details'
  }

  before_save do
    self.workflow = 'trigger'
  end

  class << self
    def type_abbreviation
      # This string is used when constructing paths or methods in other parts of
      # the system. Ensure that it does not come from a user-supplied parameter,
      # and does not contain special chars like slashes, etc.
      'SAR_INTERNAL_REVIEW'
    end

    def state_machine_name
      'sar_internal_review'
    end

    def human_attribute_name(attr, options = {})
      HUMANIZED_ATTRIBUTES[attr.to_sym] || super
    end

    def steppable?
      true
    end
  end

  enum sar_ir_subtype: {
    timeliness: 'timeliness',
    compliance: 'compliance'
  }

end
