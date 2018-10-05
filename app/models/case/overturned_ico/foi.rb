class Case::OverturnedICO::FOI < Case::OverturnedICO::Base

  has_paper_trail only: [
    :ico_reference,
    :escalation_deadline,
    :external_deadline,
    :internal_deadline,
    :reply_method,
    :email,
    :post_address,
    :original_ico_appeal,
    :original_case,
    :date_received
]

  def correspondence_type_for_business_unit_assignment
    CorrespondenceType.foi
  end

  def overturned_ico_foi?
    true
  end

  def state_machine_name
    'foi'
  end

  def self.type_abbreviation
    'OVERTURNED_FOI'
  end

  def validate_original_ico_appeal
    if original_ico_appeal.blank?
      errors.add(:original_ico_appeal, :blank)
    else
      unless original_ico_appeal.is_a?(Case::ICO::FOI)
        errors.add(:original_ico_appeal, :not_ico_foi)
      end
    end
  end
end
