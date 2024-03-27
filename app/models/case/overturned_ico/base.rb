# == Schema Information
#
# Table name: cases
#
#  id                       :integer          not null, primary key
#  name                     :string
#  email                    :string
#  message                  :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  received_date            :date
#  postal_address           :string
#  subject                  :string
#  properties               :jsonb
#  requester_type           :enum
#  number                   :string           not null
#  date_responded           :date
#  outcome_id               :integer
#  refusal_reason_id        :integer
#  current_state            :string
#  last_transitioned_at     :datetime
#  delivery_method          :enum
#  workflow                 :string
#  deleted                  :boolean          default(FALSE)
#  info_held_status_id      :integer
#  type                     :string
#  appeal_outcome_id        :integer
#  dirty                    :boolean          default(FALSE)
#  reason_for_deletion      :string
#  user_id                  :integer          default(-100), not null
#  reason_for_lateness_id   :bigint
#  reason_for_lateness_note :string
#

class Case::OverturnedICO::Base < Case::Base
  include LinkableOriginalCase

  before_save do
    self.workflow = "standard" if workflow.nil?
  end

  jsonb_accessor :properties,
                 ico_officer_name: :string,
                 escalation_deadline: :date,
                 internal_deadline: :date,
                 external_deadline: :date,
                 reply_method: :string,
                 late_team_id: :integer,
                 date_draft_compliant: :date

  delegate :ico_reference_number, to: :original_ico_appeal
  delegate :ico_decision, to: :original_ico_appeal
  delegate :ico_decision_comment, to: :original_ico_appeal
  delegate :date_ico_decision_received, to: :original_ico_appeal
  delegate :ico_decision_attachments, to: :original_ico_appeal

  enum reply_method: {
    send_by_post: "send_by_post",
    send_by_email: "send_by_email",
  }

  before_validation :copy_ico_officer_name

  validate :validate_received_date
  validate :validate_external_deadline
  validate :validate_original_ico_appeal

  validates :ico_officer_name, presence: true
  validates :original_case, presence: true
  validates :reply_method, presence: true
  validates :email,          presence: { if: :send_by_email? }
  validates :postal_address, presence: { if: :send_by_post? }

  has_one :original_ico_appeal_link,
          -> { original_appeal },
          class_name: "LinkedCase",
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
    original_ico_appeal&.id
  end

  def overturned_ico?
    true
  end

  # link cases linked to the original case and original appeal to this case
  def link_related_cases
    [original_case, original_ico_appeal].each { |source_case| link_cases_related_to(source_case) }
  end

private

  def copy_ico_officer_name
    if new_record? && original_ico_appeal.respond_to?(:ico_officer_name) && ico_officer_name.blank?
      self.ico_officer_name = original_ico_appeal.ico_officer_name
    end
  end

  def identifier
    message
  end

  # link the cases linked to the source case to this case, unless already linked
  # then link THIS case to the source case
  def link_cases_related_to(source_case)
    source_case.linked_cases.each do |kase_to_be_linked|
      if !linked_cases.include?(kase_to_be_linked) && kase_to_be_linked != self
        linked_cases << kase_to_be_linked
      end
    end
  end

  def set_deadlines
    self.internal_deadline = 20.business_days.before(external_deadline)
    self.escalation_deadline = created_at.to_date
  end

  def validate_received_date
    if received_date.blank?
      errors.add(:received_date, :blank)
    elsif received_date > Time.zone.today
      errors.add(:received_date, :future)
    elsif received_date <= Time.zone.today - 41.days && new_record?
      errors.add(:received_date, :past)
    end
  end

  def validate_external_deadline
    if external_deadline.blank?
      errors.add(:external_deadline, :blank)
    elsif external_deadline < Time.zone.today && new_record?
      errors.add(:external_deadline, :past)
    elsif external_deadline > Time.zone.today + 50.days
      errors.add(:external_deadline, :future)
    end
  end

  def validate_original_ico_appeal
    raise "Implement this method in the derived class"
  end
end
