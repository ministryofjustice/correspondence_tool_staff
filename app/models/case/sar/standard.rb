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

class Case::SAR::Standard < Case::Base
  class << self
    def type_abbreviation
      # This string is used when constructing paths or methods in other parts of
      # the system. Ensure that it does not come from a user-supplied parameter,
      # and does not contain special chars like slashes, etc.
      "SAR"
    end
  end

  include DraftTimeliness::ProgressedForClearance

  before_save do
    self.workflow = "standard" if workflow.nil?
  end

  def self.searchable_fields_and_ranks
    super.merge({ subject_full_name: "B" })
  end

  jsonb_accessor :properties,
                 escalation_deadline: :date,
                 internal_deadline: :date,
                 external_deadline: :date,
                 subject_full_name: :string,
                 subject_type: :string,
                 third_party: :boolean,
                 third_party_relationship: :string,
                 reply_method: :string,
                 request_method: :string,
                 late_team_id: :integer,
                 date_draft_compliant: :date,
                 # indicate whether the deadline has been extended
                 deadline_extended: [:boolean, { default: false }],
                 # indicate how long has been extended so far in time units
                 extended_times: :integer

  attr_accessor :missing_info

  enum :subject_type, {
    offender: "offender",
    staff: "staff",
    member_of_the_public: "member_of_the_public",
  }

  enum :reply_method, {
    send_by_post: "send_by_post",
    send_by_email: "send_by_email",
  }

  enum :request_method, {
    email: "email",
    verbal: "verbal",
    post: "post",
    web_portal: "web_portal",
    unknown: "unknown",
  }

  has_paper_trail only: %i[
    name
    email
    postal_address
    properties
    received_date
    subject
  ]

  validates :subject_full_name, presence: true
  validates :third_party, inclusion: { in: [true, false], message: "Please choose yes or no" }

  validates :reply_method, presence: true
  validates :subject_type, presence: true
  validates :request_method, presence: { unless: :sar_internal_review? }

  validate :validate_name
  validate :validate_third_party_relationship
  validate :validate_email_address
  validate :validate_postal_address
  validates :subject, presence: true, length: { maximum: 100 }
  validate :validate_message_or_uploaded_request_files, on: :create
  validate :validate_message_or_attached_request_files, on: :update

  before_save :use_subject_as_requester,
              if: -> { name.blank? }
  after_create :process_uploaded_request_files,
               if: -> { uploaded_request_files.present? }

  # The method below is overriding the close method in the case_states.rb file.
  # This is so that the case is closed with the responder's team instead of the manager's team

  def validate_name
    if third_party && name.blank?
      errors.add(
        :name,
        :blank,
      )
    end
  end

  def validate_third_party_relationship
    if third_party && third_party_relationship.blank?
      errors.add(
        :third_party_relationship,
        :blank,
      )
    end
  end

  def respond_and_close(current_user)
    state_machine.respond!(acting_user: current_user, acting_team: responding_team)
    state_machine.close!(acting_user: current_user, acting_team: responding_team)
  end

  def within_escalation_deadline?
    false
  end

  def sar?
    true
  end

  def deadline_extendable?
    max_allowed_deadline_date > external_deadline
  end

  def initial_deadline
    sar_extensions = transitions
      .where(event: "extend_sar_deadline")
      .order(:id)

    if sar_extensions.any?
      sar_extensions.first.original_final_deadline
    else
      external_deadline
    end
  end

  def extend_deadline!(new_deadline, new_extended_times)
    update!(
      external_deadline: new_deadline,
      deadline_extended: true,
      extended_times: new_extended_times,
    )
  end

  def reset_deadline!
    update!(
      external_deadline: @deadline_calculator.external_deadline,
      deadline_extended: false,
      extended_times: 0,
    )
  end

  # The deadlines are all calculated based on the date case is received
  def max_allowed_deadline_date
    @deadline_calculator.max_allowed_deadline_date(max_time_limit)
  end

  def extension_time_limit
    correspondence_type.extension_time_limit || Settings.sar_extension_default_limit
  end

  def extension_time_default
    correspondence_type.extension_time_default || Settings.sar_extension_default_time_gap
  end

  def self.factory(type)
    case type&.downcase
    when "standard"
      self
    when "offender"
      Case::SAR::Offender
    end
  end

  def self.ico_model
    Case::ICO::SAR
  end

  def stoppable?
    true
  end

private

  def update_deadlines
    if changed.include?("received_date") && !extended_for_pit?
      self.internal_deadline = @deadline_calculator.internal_deadline
      self.external_deadline = @deadline_calculator.external_deadline
      self.extended_times = 0
      self.deadline_extended = false
    end
  end

  def max_time_limit
    correspondence_type.extension_time_limit || Settings.sar_extension_default_limit
  end

  def use_subject_as_requester
    self.name = subject_full_name
  end

  def validate_postal_address
    if send_by_post? && postal_address.blank?
      errors.add(
        :postal_address,
        :blank,
      )
    end
  end

  def validate_email_address
    if send_by_email? && email.blank?
      errors.add(
        :email,
        :blank,
      )
    end
  end

  def validate_message_or_uploaded_request_files
    if message.blank? && uploaded_request_files.blank?
      errors.add(
        :message,
        :blank,
        message: "cannot be blank if no request files attached",
      )

      errors.add(
        :uploaded_request_files,
        :blank,
        message: "cannot be blank if no case details entered",
      )
    end
  end

  def validate_message_or_attached_request_files
    if message.blank? && attachments.request.blank?
      errors.add(
        :message,
        :blank,
        message: "cannot be blank if no request files attached",
      )
    end
  end
end
