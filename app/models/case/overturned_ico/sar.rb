class Case::OverturnedICO::SAR < Case::OverturnedICO::Base

  delegate :message, to: :original_case

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

  attr_accessor :missing_info

  def correspondence_type_for_business_unit_assignment
    CorrespondenceType.sar
  end

  def self.state_machine_name
    'sar'
  end

  def within_escalation_deadline?
    false
  end

  def self.type_abbreviation
    'OVERTURNED_SAR'
  end

  def validate_original_ico_appeal
    if original_ico_appeal.blank?
      errors.add(:original_ico_appeal, :blank)
    else
      unless original_ico_appeal.is_a?(Case::ICO::SAR)
        errors.add(:original_ico_appeal, :not_ico_sar)
      end
    end
  end

  def overturned_ico_sar?
    true
  end

  def respond_and_close(current_user)
    state_machine.respond!(acting_user: current_user, acting_team: self.responding_team)
    state_machine.close!(acting_user: current_user, acting_team: self.responding_team)
  end


end
