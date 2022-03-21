class Case::SAR::InternalReview < Case::SAR::Standard

  include LinkableOriginalCase

  # override parent class callback behaviour
  # as not required for SAR::InternalReview cases
  skip_callback :save, :before, :use_subject_as_requester

  belongs_to :sar_ir_outcome, class_name: 'CaseClosure::AppealOutcome'

  validates_presence_of :original_case
  validates_presence_of :sar_ir_subtype

  attr_accessor :original_case_number

  jsonb_accessor :properties,
                 sar_ir_subtype: :string,
                 team_responsible_for_outcome_id: :integer,
                 other_overturned: :string
                

  HUMANIZED_ATTRIBUTES = {
    sar_ir_subtype: 'Case type',
    subject: 'Case summary',
    message: 'Full case details',
    original_case: 'The original case'
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

  def closed_for_reporting_purposes?
    closed? || responded?
  end

  def sar_ir_outcome
    appeal_outcome&.name
  end

  def sar_ir_outcome_abbr
    appeal_outcome&.abbreviation
  end

  def sar_ir_outcome=(name)
    self.appeal_outcome = CaseClosure::AppealOutcome.by_name(name)
  end

  def validate_case_link(type, linked_case, attribute)
    linkable = CaseLinkTypeValidator.classes_can_be_linked_with_type?(
      klass: self.class.to_s,
      linked_klass: linked_case.class.to_s,
      type: type
    )

    unless linkable
      errors.add(
        attribute,
        :wrong_type,
        message: I18n.t('activerecord.errors.models.case/sar/internal_review.attributes.linked_case.wrong_type')
      )
    end
  end
end
