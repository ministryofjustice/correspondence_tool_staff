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
                 priority: :string

  validates :complaint_type, presence: true
  validates :complaint_subtype, presence: true
  validates :priority, presence: true
  validate :validate_ico_contact_name
  validate :validate_ico_contact_details
  validate :validate_ico_reference

  enum complaint_type: {
    standard: 'standard',
    ico_complaint: 'ico_complaint',
    litigation: 'litigation',
  }

  enum complaint_subtype: {
    missing_data: 'missing_data',
    inaccurate_data: 'inaccurate_data',
    redacted_data: 'redacted_data',
    timeliness: 'timeliness',
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
    if litigation? && gld_contact_name.blank?
      errors.add(
        :gld_contact_name,
        I18n.t('activerecord.errors.models.case/sar/offender_complaint.attributes.gld_contact_name.blank')
      )
    end
    errors[:gld_contact_name].any?
  end

  def validate_gld_contact_details
    if litigation? && gld_contact_email.blank? && gld_contact_phone.blank?
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
    if litigation? && gld_reference.blank?
      errors.add(
        :gld_reference,
        I18n.t('activerecord.errors.models.case/sar/offender_complaint.attributes.gld_reference.blank')
      )
    end
    errors[:gld_reference].any?
  end


  private

  def stamp_on_original_case
    self.original_case.state_machine.add_note_to_case!(
      acting_user: self.creator,
      acting_team: self.creator.case_team(self.original_case),
      message: I18n.t(
        'common.case/offender_sar.complaint_case_link_message',
        received_date: self.received_date.to_date))
  end

end
