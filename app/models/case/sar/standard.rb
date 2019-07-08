# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  delivery_method      :enum
#  workflow             :string
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

class Case::SAR::Standard < Case::Base
  class << self
    def type_abbreviation
      # This string is used when constructing paths or methods in other parts of
      # the system. Ensure that it does not come from a user-supplied parameter,
      # and does not contain special chars like slashes, etc.
      'SAR'
    end
  end

  include DraftTimeliness::ProgressedForClearance

  before_save do
    self.workflow = 'standard' if workflow.nil?
  end

  def self.searchable_fields_and_ranks
    super.merge({ subject_full_name: 'B' })
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
                 late_team_id: :integer,
                 date_draft_compliant: :date,
                 deadline_extended: [:boolean, default: false]

  attr_accessor :missing_info

  enum subject_type: {
    offender_sar: 'offender',
    staff: 'staff',
    member_of_the_public: 'member_of_the_public'
  }

  enum reply_method: {
    send_by_post: 'send_by_post',
    send_by_email: 'send_by_email',
  }

  has_paper_trail only: [
    :name,
    :email,
    :postal_address,
    :properties,
    :received_date,
    :subject,
  ]

  validates_presence_of :subject_full_name
  validates :third_party, inclusion: {in: [ true, false ], message: "Please choose yes or no" }

  validates_presence_of :name, :third_party_relationship, if: -> { third_party }
  validates_presence_of :reply_method
  validates_presence_of :subject_type
  validates_presence_of :email,          if: :send_by_email?
  validates_presence_of :postal_address, if: :send_by_post?
  validates :subject, presence: true, length: { maximum: 100 }
  validate :validate_message_or_uploaded_request_files, on: :create
  validate :validate_message_or_attached_request_files, on: :update

  before_save :use_subject_as_requester,
              if: -> { name.blank? }
  after_create :process_uploaded_request_files,
               if: -> { uploaded_request_files.present? }

  # The method below is overriding the close method in the case_states.rb file.
  # This is so that the case is closed with the responder's team instead of the manager's team

  def respond_and_close(current_user)
    state_machine.respond!(acting_user: current_user, acting_team: self.responding_team)
    state_machine.close!(acting_user: current_user, acting_team: self.responding_team)
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
    sar_extensions = self.transitions
      .where(event: 'extend_sar_deadline')
      .order(:id)

    if sar_extensions.any?
      sar_extensions.first.original_final_deadline
    else
      external_deadline
    end
  end

  def extend_deadline!(new_deadline)
    self.update!(
      external_deadline: new_deadline,
      deadline_extended: true
    )
  end

  def reset_deadline!
    self.update!(
      external_deadline: initial_deadline,
      deadline_extended: false
    )
  end

  # SARs extensions are based on calendar days not working days
  def max_allowed_deadline_date
    initial_deadline + Settings.sar_extension_limit.to_i.days
  end

  def self.factory(type)
    case type&.downcase
    when 'standard'
      self
    when 'offender'
      Case::SAR::Offender
    end
  end

  def self.ico_model
    Case::ICO::SAR
  end

  private

  def use_subject_as_requester
    self.name = self.subject_full_name
  end

  def validate_message_or_uploaded_request_files
    if message.blank? && uploaded_request_files.blank?
      errors.add(
        :message,
        :blank,
        message: "can't be blank if no request files attached"
      )

      errors.add(
        :uploaded_request_files,
        :blank,
        message: "can't be blank if no case details entered"
      )
    end
  end

  def validate_message_or_attached_request_files
    if message.blank? && attachments.request.blank?
      errors.add(
        :message,
        :blank,
        message: "can't be blank if no request files attached"
      )
    end
  end
end



