class Case::SAR::OffenderComplaint < Case::SAR::Offender

  include LinkableOriginalCase

  validates_presence_of :original_case
  after_create :stamp_on_original_case

  jsonb_accessor :properties,
                 complaint_type: :string,
                 complaint_subtype: :string,
                 ico_contact_name: :string,
                 ico_contact_email: :string,
                 ico_contact_phone: :string,
                 ico_reference: :string,
                 gld_contact_name: :string,
                 gld_contact_email: :string,
                 gld_contact_phone: :string,
                 gld_reference: :string,
                 priority: :string, 
                 total_cost: :decimal, 
                 settlement_cost: :decimal,
                 approval_flag_ids: [:integer, array: true, default: []]

  validates :complaint_type, presence: true
  validates :complaint_subtype, presence: true
  validates :priority, presence: true
  validate :validate_ico_contact_name
  validate :validate_ico_contact_details
  validate :validate_ico_reference
  validate :validate_gld_contact_name
  validate :validate_gld_contact_details
  validate :validate_gld_reference
  validate :validate_external_deadline

  belongs_to :appeal_outcome, class_name: 'CaseClosure::OffenderComplaintAppealOutcome'
  belongs_to :outcome, class_name: 'CaseClosure::OffenderComplaintOutcome'

  enum complaint_type: {
    standard_complaint: 'standard_complaint',
    ico_complaint: 'ico_complaint',
    litigation_complaint: 'litigation',
  }

  enum complaint_subtype: {
    sscl_partial_case: 'sscl_partial_case',
    covid_partial_response: 'covid_partial_response',
    missing_data: 'missing_data',
    inaccurate_data: 'inaccurate_data',
    redacted_data: 'redacted_data',
    timeliness: 'timeliness',
    not_applicable: 'not_applicable'
  }

  enum priority: {
    normal:  'normal',
    high: 'high',
  }

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
    validate_external_deadline_required
    validate_external_deadline_within_valid_range
  end

  def normal_priority?
    normal?
  end

  def high_priority?
    high?
  end

  def validate_ico_contact_name
    if ico_complaint? && ico_contact_name.blank?
      errors.add(
        :ico_contact_name,
        I18n.t('activerecord.errors.models.case/sar/offender_complaint.attributes.ico_contact_name.blank')
      )
    end
    errors[:ico_contact_name].any?
  end

  def validate_ico_contact_details
    if ico_complaint? && ico_contact_email.blank? && ico_contact_phone.blank?
      errors.add(
          :ico_contact_email,
          I18n.t('activerecord.errors.models.case/sar/offender_complaint.attributes.ico_contact_email.blank')
      )
      errors.add(
          :ico_contact_phone,
          I18n.t('activerecord.errors.models.case/sar/offender_complaint.attributes.ico_contact_phone.blank')
      )
    end
    errors[:ico_contact_email].any? || errors[:ico_contact_phone].any?
  end

  def validate_ico_reference
    if ico_complaint? && ico_reference.blank?
      errors.add(
        :ico_reference,
        I18n.t('activerecord.errors.models.case/sar/offender_complaint.attributes.ico_reference.blank')
      )
    end
    errors[:ico_reference].any?
  end

  def validate_gld_contact_name
    if litigation_complaint? && gld_contact_name.blank?
      errors.add(
        :gld_contact_name,
        I18n.t('activerecord.errors.models.case/sar/offender_complaint.attributes.gld_contact_name.blank')
      )
    end
    errors[:gld_contact_name].any?
  end

  def validate_gld_contact_details
    if litigation_complaint? && gld_contact_email.blank? && gld_contact_phone.blank?
      errors.add(
          :gld_contact_email,
          I18n.t('activerecord.errors.models.case/sar/offender_complaint.attributes.gld_contact_email.blank')
      )
      errors.add(
          :gld_contact_phone,
          I18n.t('activerecord.errors.models.case/sar/offender_complaint.attributes.gld_contact_phone.blank')
      )
    end
    errors[:gld_contact_email].any? || errors[:gld_contact_phone].any?
  end

  def validate_gld_reference
    if litigation_complaint? && gld_reference.blank?
      errors.add(
        :gld_reference,
        I18n.t('activerecord.errors.models.case/sar/offender_complaint.attributes.gld_reference.blank')
      )
    end
    errors[:gld_reference].any?
  end

  def assigned?
    Assignment.where(case_id: self.id, role: 'responding').count > 0
  end

  def approval_flags
    CaseClosure::Metadatum.where(id: approval_flag_ids)
  end

  def has_costs?
    has_settlement_cost? || has_total_cost?
  end 

  private

  def validate_external_deadline_required
    if require_external_deadline? && external_deadline.blank?
      errors.add(:external_deadline, :blank)
    end
  end

  def validate_external_deadline_within_valid_range
    if received_date.present? && external_deadline.present? && external_deadline < received_date
      errors.add(:external_deadline, :before_received)
    end
    if external_deadline.present? && external_deadline < Date.today && self.new_record?
      errors.add(:external_deadline, :past)
    end
  end

  def require_external_deadline?
    received_date.present?
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

  def set_number
    if self.original_case.present?
      self.number = next_number_from_original_case
    else
      next_number
    end
  end
  
  def next_number_from_original_case
    # It should be rare that multiple persons are trying to create a new complaint 
    # against the same original case and submit nearly at the same time. So IMO (yikang)
    # it is not worth trying to track the counter per cases level at DB like case number for other types, 
    # simple appoach here is to try 2 times only if the case number somehow is duplicated by any chance
    begin
      retries ||= 0
      counter = self.original_case.case_links.count
      counter_str = counter > 0 ? "-#{counter.to_s.rjust(3, "0")}" : ""
      new_case_number = "Q#{self.original_case.number}#{counter_str}"
      raise "Duplicate case number, please try again " if Case::Base.find_by(number: new_case_number).present?
      new_case_number
    rescue
      retry if (retries += 1) < 3
    end
  end

  def has_settlement_cost?
    self.settlement_cost.present? && self.settlement_cost > 0
  end

  def has_total_cost?
    self.total_cost.present? && self.total_cost > 0
  end

end
