class Case::SAR::InternalReview < Case::SAR::Standard

  include LinkableOriginalCase

  belongs_to :sar_ir_outcome, class_name: 'CaseClosure::AppealOutcome'

  validates_presence_of :original_case
  validates_presence_of :sar_ir_subtype

  attr_accessor :original_case_number



  jsonb_accessor :properties,
                 sar_ir_subtype: :string,
                 team_responsible_for_outcome_id: :integer

  HUMANIZED_ATTRIBUTES = {
    sar_ir_subtype: 'Case type',
    subject: 'Case summary',
    message: 'Full case details'
  }

  before_save do
    self.workflow = 'trigger'
  end

  def respond_and_close(current_user)
    state_machine.respond!(acting_user: current_user, acting_team: self.managing_team)
    state_machine.close!(acting_user: current_user, acting_team: self.managing_team)
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

  def sar_ir_outcome
    appeal_outcome&.name
  end

  def sar_ir_outcome=(name)
    self.appeal_outcome = CaseClosure::AppealOutcome.by_name(name)
  end
end
