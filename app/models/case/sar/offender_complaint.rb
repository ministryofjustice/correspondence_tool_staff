class Case::SAR::OffenderComplaint < Case::SAR::Offender

  include LinkableOriginalCase

  validates_presence_of :original_case
  after_create :stamp_on_original_case

  jsonb_accessor :properties,
                 complaint_type: :string,
                 complaint_subtype: :string,
                 priority: :string

  validates :complaint_type, presence: true
  validates :complaint_subtype, presence: true
  validates :priority, presence: true
  validate :validate_external_deadline

  enum complaint_type: {
    standard:  'standard',
    ico: 'ico',
    litigation: 'litigation',
  }

  enum complaint_subtype: {
    missing_data:  'missing_data',
    inaccurate_data: 'inaccurate_data',
    redacted_data: 'redacted_data',
    timeliness: 'timeliness',
  }

  enum priority: {
    normal:  'normal',
    high: 'high',
  }

  # CT-3165 WIP REQUIRED FOR VALIDATIONS
  #         REMOVE ONCE UX IS COMPLETED
  before_validation :set_types
  def set_types
    self.complaint_type = 'standard'
    self.complaint_subtype = 'missing_data'
    self.priority = 'normal'
  end
  # CT-3165 END REMOVE ONCE UX IS COMPLETED

  class << self
    def type_abbreviation
      'OFFENDER_SAR_COMPLAINT'
    end
  end

  def offender_sar_complaint?
    true
  end

  def type_of_offender_sar?
    true
  end

  def offender_sar?
    false
  end

  def validate_external_deadline
    if require_external_deadline? && external_deadline.blank?
      errors.add(:external_deadline, :blank)
    end
    if received_date.present? && external_deadline.present? && external_deadline < received_date
      errors.add(:external_deadline, :before_received)
    end
    if external_deadline.present? && external_deadline < Date.today && self.new_record?
      errors.add(:external_deadline, :past)
    end
  end

  private

  def require_external_deadline?
    received_date.present? && complaint_type.present? && (["standard", "ico"].include? complaint_type)
  end

  def stamp_on_original_case
    self.original_case.state_machine.add_note_to_case!(
      acting_user: self.creator,
      acting_team: self.creator.case_team(self.original_case),
      message: I18n.t(
        'common.case/offender_sar.complaint_case_link_message', 
        received_date: self.received_date.to_date))
  end

  def set_deadlines
    # For this case type's deadlines are manually set and don't need to be automatically
    # calculated. So this method called by a before_update hook in Case::Base
    # becomes a nop.
    nil
  end

  def update_deadlines
    # For this case type's deadlines are manually set and don't need to be automatically
    # calculated. So this method called by a before_update hook in Case::Base
    # becomes a nop.
    nil
  end
end
