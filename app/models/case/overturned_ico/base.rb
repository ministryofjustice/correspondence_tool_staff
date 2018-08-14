class Case::OverturnedICO::Base < Case::Base

  include LinkableOriginalCase

  before_save do
    self.workflow = 'standard' if workflow.nil?
  end


  jsonb_accessor :properties,
                 ico_reference: :string,
                 escalation_deadline: :date,
                 internal_deadline: :date,
                 external_deadline: :date,
                 reply_method: :string

  enum reply_method: {
      send_by_post:  'send_by_post',
      send_by_email: 'send_by_email',
  }


  validate :validate_received_date
  validate :validate_external_deadline
  validate :validate_original_ico_appeal

  validates_presence_of :original_case
  validates_presence_of :reply_method
  validates_presence_of :email,          if: :send_by_email?
  validates_presence_of :postal_address, if: :send_by_post?

  has_one :original_ico_appeal_link,
          -> { original_appeal },
          class_name: 'LinkedCase',
          foreign_key: :case_id

  has_one :original_ico_appeal,
          through: :original_ico_appeal_link,
          source: :linked_case

  def subject
    original_case&.subject
  end

  def delivery_method
    self[:delivery_method].nil? ? original_case&.delivery_method : self[:delivery_method]
  end

  def requires_flag_for_disclosure_specialists?
    false
  end

  def original_ico_appeal_id=(case_id)
    self.original_ico_appeal = Case::Base.find(case_id)
  end

  def original_ico_appeal_id
    self.original_ico_appeal&.id
  end

  def set_reply_method
    self.reply_method = original_case.reply_method
    self.email = original_case.email
    self.postal_address = original_case.postal_address
  end

  private

  def set_deadlines
    self.internal_deadline = 20.business_days.before(self.external_deadline)
  end

  def validate_received_date
    if received_date.blank?
      errors.add(:received_date, :blank)
    elsif received_date > Date.today
      errors.add(:received_date, :future)
    elsif received_date < Date.today - 4.weeks  && self.new_record?
      errors.add(:received_date, :past)
    end
  end

  def validate_external_deadline
    if external_deadline.blank?
      errors.add(:external_deadline, :blank)
    elsif external_deadline < Date.today && self.new_record?
      errors.add(:external_deadline, :past)
    elsif external_deadline > Date.today + 50.days
      errors.add(:external_deadline, :future)
    end
  end

  def validate_original_ico_appeal
    raise "Implement this method in the derived class"
  end

end
