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
#  category_id          :integer
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
#  deleted?             :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string           default("Case")
#  appeal_outcome_id    :integer
#

#rubocop:disable Metrics/ClassLength
class Case < ApplicationRecord
  include Statesman::Adapters::ActiveRecordQueries

  default_scope { where( deleted?: false) }

  has_paper_trail only: %i{ name email received_date subject postal_address requester_type }


  enum requester_type: {
         academic_business_charity: 'academic_business_charity',
         journalist: 'journalist',
         member_of_the_public: 'member_of_the_public',
         offender: 'offender',
         solicitor: 'solicitor',
         staff_judiciary: 'staff_judiciary',
         what_do_they_know: 'what_do_they_know'
       }

  enum delivery_method: {
         sent_by_post: 'sent_by_post',
         sent_by_email: 'sent_by_email',
       }

  jsonb_accessor :properties,
                 escalation_deadline: :date,
                 internal_deadline: :date,
                 external_deadline: :date

  attr_accessor :flag_for_disclosure_specialists,
                :uploaded_request_files,
                :request_amends_comment,
                :upload_comment,
                :uploading_user # Used when creating case sent by post.

  attr_accessor :message_text

  acts_as_gov_uk_date :received_date, :date_responded,
                      validate_if: :received_in_acceptable_range?

  scope :by_deadline, -> {
    select("\"cases\".*, (properties ->> 'external_deadline')::timestamp with time zone, cases.id")
      .order("(properties ->> 'external_deadline')::timestamp with time zone ASC, cases.id")
  }
  scope :most_recent_first, -> {reorder("(properties ->> 'external_deadline')::timestamp with time zone DESC, cases.id") }

  scope :opened, -> { where.not(current_state: 'closed') }
  scope :closed, -> { where(current_state: 'closed').order(last_transitioned_at: :desc) }

  scope :with_teams, -> (teams) do
    includes(:assignments)
      .where(assignments: { team: teams,
                            state: ['pending', 'accepted']})
  end
  scope :not_with_teams, -> (teams) do
    where.not(id: Case.with_teams(teams).pluck(:id))
  end

  scope :in_states, -> (states) { where(current_state: states) }

  scope :with_user, ->(*users, states: ['pending', 'accepted']) do
    joins(:assignments)
      .where(assignments: { user_id: users.map { |u| u.id },
                            state: states})
  end

  scope :accepted, -> { joins(:assignments)
                          .where(assignments: {state: ['accepted']} ) }
  scope :unaccepted, -> { joins(:assignments)
                            .where.not(assignments: {state: 'accepted'} ) }

  scope :waiting_to_be_accepted, ->(*teams) do
    includes(:assignments)
      .where(assignments: { team_id: teams.map { |t| t.id },
                            state: ['pending']})
  end

  scope :flagged_for_approval, ->(*teams) do
    joins(:assignments)
      .where(assignments: { team_id: teams.map(&:id), role: 'approving' })
  end

  scope :in_time, -> {
    where(
      "CASE WHEN current_state = 'closed' THEN date_responded <= (properties->>'external_deadline')::date ELSE ? <= properties->>'external_deadline' END",
      Date.today
    )
  }
  scope :late, -> {
    where(
      "CASE WHEN current_state = 'closed' THEN date_responded > (properties->>'external_deadline')::date ELSE ? > properties->>'external_deadline' END",
      Date.today
    )
  }

  scope :search, ->(query) { where(number: query) }

  validates :current_state, presence: true, on: :update

  validates :name,presence: true

  validates :email, presence: true, on: :create, if: -> { postal_address.blank? }
  validates :email, format: { with: /\A.+@.+\z/ }, if: -> { email.present? }
  validates :postal_address,
            presence: true,
            on: :create,
            if: -> { email.blank? || sent_by_post? }
  validates :requester_type, :received_date, :delivery_method , presence: true
  validates :message, presence: true, if: -> { sent_by_email? }
  validates :uploaded_request_files,
            presence: true,
            on: :create,
            if: -> { sent_by_post? }
  validates :subject,  :category, presence: true
  validates :subject, length: { maximum: 100 }
  validates :type, presence: true

  validates_with ::ClosedCaseValidator

  serialize :exemption_ids, Array

  belongs_to :category, required: true

  has_many :assignments, dependent: :destroy

  has_many :teams, through: :assignments

  has_one :managing_assignment,
          -> { managing },
          class_name: 'Assignment'

  has_one :manager,
          through: :managing_assignment,
          source: :user

  has_one :managing_team,
          through: :managing_assignment,
          source: :team

  has_one :responder,
          through: :responder_assignment,
          source: :user

  has_one :responder_assignment,
          -> { last_responding },
          class_name: 'Assignment'

  has_one :responder,
          through: :responder_assignment,
          source: :user

  has_one :responding_team,
          through: :responder_assignment,
          source: :team
  accepts_nested_attributes_for :responding_team

  has_many :responding_team_users,
           through: :responding_team,
           source: :users

  has_many :approver_assignments,
          -> { approving },
          class_name: 'Assignment'

  has_many :approvers,
           through: :approver_assignments,
           source: :user

  has_many :approving_teams,
           -> { where("state != 'rejected'") },
           class_name: BusinessUnit,
           through: :approver_assignments,
           source: :team

  has_many :approving_team_users,
           through: :approving_teams,
           source: :users

  has_many :transitions,
           class_name: 'CaseTransition',
           autosave: false,
           dependent: :destroy do
              def most_recent
                where(most_recent: true).first
              end
           end
  has_many :message_transitions,
           -> { messages },
           class_name: 'CaseTransition'
  has_many :users_transitions_trackers,
           class_name: 'CasesUsersTransitionsTracker'

  has_many :responded_transitions, -> { responded }, class_name: 'CaseTransition'

  has_many :attachments, -> { order(id: :desc) }, class_name: 'CaseAttachment', dependent: :destroy

  belongs_to :outcome, class_name: 'CaseClosure::Outcome'

  belongs_to :appeal_outcome, class_name: 'CaseClosure::AppealOutcome'

  belongs_to :refusal_reason, class_name: 'CaseClosure::RefusalReason'

  belongs_to :info_held_status, class_name: 'CaseClosure::InfoHeldStatus'

  has_and_belongs_to_many :exemptions, class_name: 'CaseClosure::Exemption', join_table: 'cases_exemptions'

  has_and_belongs_to_many :linked_cases,
                          class_name: Case,
                          join_table: 'linked_cases',
                          foreign_key: :case_id,
                          association_foreign_key: :linked_case_id

  before_create :set_initial_state,
                :set_number,
                :set_managing_team,
                :set_deadlines
  before_save :prevent_number_change
  after_create :process_uploaded_request_files, if: :sent_by_post?

  delegate :available_events, to: :state_machine

  Cases::FOIStateMachine.states.each do |state|
    define_method("#{state}?") { current_state == state }
  end

  include CaseStates

  def upload_response_groups
    CaseAttachmentUploadGroupCollection.new(self, attachments.response)
  end

  def upload_request_groups
    CaseAttachmentUploadGroupCollection.new(self, attachments.request)
  end

  def info_held_status_abbreviation
    info_held_status&.abbreviation
  end

  def info_held_status_abbreviation=(value)
    self.info_held_status_id = CaseClosure::InfoHeldStatus.id_from_abbreviation(value)
  end

  def default_team_service
    @default_team_service ||= DefaultTeamService.new(self)
  end

  def team_for_user(user)
    assignments.where(user_id: user.id).first&.team ||
      (teams & user.teams).first
  end

  def allow_event?(user, event)
    state_machine.permitted_events(user.id).include?(event)
  end

  def prevent_number_change
    raise StandardError.new('number is immutable') if number_changed?
  end

  def triggerable?
    !requires_clearance?
  end

  def under_review?
    triggerable? && within_escalation_deadline?
  end

  def within_escalation_deadline?
    escalation_deadline.future? || escalation_deadline.today?
  end

  def within_external_deadline?
    date_responded <= external_deadline
  end

  def attachments_dir(attachment_type, upload_group)
    "#{S3Uploader.id_for_case(self)}/#{attachment_type}/#{upload_group}"
  end

  def uploads_dir(attachment_type)
    "#{S3Uploader.id_for_case(self)}/#{attachment_type}"
  end

  def outcome_name
    outcome&.name
  end

  def outcome_name=(name)
    self.outcome = CaseClosure::Outcome.by_name(name)
  end

  def refusal_reason_name
    refusal_reason&.name
  end

  def refusal_reason_name=(name)
    self.refusal_reason = CaseClosure::RefusalReason.by_name(name)
  end

  # returns a hash which can be used by for populating checkboxes
  # e.g. {"10"=>"1", "11"=>"1", "12"=>"0", "13"=>"0", "14"=>"1"}
  def exemption_ids
    exemption_hash = {}
    exemptions.map{ |ex| exemption_hash[ex.id.to_s] = '1' }
    exemption_hash
  end

  # expects a hash of ids and values 1 or zero
  # e.g. {"10"=>"1", "11"=>"1", "12"=>"0", "13"=>"0", "14"=>"1"}
  def exemption_ids=(param_hash)
    exemption_ids = param_hash.select { |_exemption_id, val| val == '1' }.keys
    self.exemptions = CaseClosure::Exemption.find(exemption_ids)
  end

  def prepare_for_close
    @preparing_for_close = true
  end

  def prepared_for_close?
    @preparing_for_close == true
  end

  def requires_exemption?
    refusal_reason.present? && refusal_reason.requires_exemption?
  end

  # case is flagged, and still requires at least one response from an approver
  def requires_clearance?
    flagged? && approver_assignments.unapproved.any?
  end

  # def case is flagged
  def flagged?
    approver_assignments.any?
  end

  def does_not_require_clearance?
    !requires_clearance?
  end

  def with_teams?(*teams)
    assignments.with_teams(teams).any?
  end

  def flagged_for_disclosure_specialist_clearance?
    approving_teams.include?(BusinessUnit.dacu_disclosure)
  end

  def flagged_for_press_office_clearance?
    approving_teams.include?(BusinessUnit.press_office)
  end

  def flagged_for_private_office_clearance?
    approving_teams.include?(BusinessUnit.private_office)
  end

  def responded?
    transitions.where(event: 'respond').any?
  end

  def responded_in_time?
    return false unless closed?
    date_responded <= external_deadline
  end

  def already_late?
    Date.today > external_deadline
  end

  def current_team_and_user
    CurrentTeamAndUserService.new(self)
  end

  def approver_assignment_for(team)
    approver_assignments.where(team: team).first
  end

  def non_default_approver_assignments
    approver_assignments.where.not(team: default_team_service.approving_team)
  end

  def transition_tracker_for_user(user)
    users_transitions_trackers.where(user: user).singular_or_nil
  end

  def sync_transition_tracker_for_user(user)
    CasesUsersTransitionsTracker.sync_for_case_and_user(self, user)
  end

  def format_workflow_class_name(type_template, type_workflow_template)
    if workflow.present?
      type_workflow_template % {type: category.abbreviation, workflow: workflow}
    else
      type_template % {type: category.abbreviation}
    end
  end

  def add_linked_case(linked_case)
    ActiveRecord::Base.transaction do
      unless self.linked_cases.include? linked_case
        self.linked_cases << linked_case
      end

      unless linked_case.linked_cases.include? self
        linked_case.linked_cases << self
      end
    end
  end

  def is_internal_review?
    self.is_a?(Case::FOI::InternalReview)
  end

  private
  def received_in_acceptable_range?
    if self.new_record? || received_date_changed?
      validate_received_date
    end
  end

  def validate_received_date
    if received_date.present? && self.received_date > Date.today
      errors.add(
        :received_date,
        I18n.t('activerecord.errors.models.case.attributes.received_date.not_in_future')
      )
    elsif received_date.present? && self.received_date < Date.today - 60.days
      errors.add(
        :received_date,
        I18n.t('activerecord.errors.models.case.attributes.received_date.past')
      )
    end
    errors[:received_date].any?
  end

  def received_date_changed?
    self.received_date != self.received_date_was
  end

  def set_initial_state
    self.current_state = self.state_machine.current_state
    self.last_transitioned_at = Time.now
  end

  def set_deadlines
    self.escalation_deadline = DeadlineCalculator.escalation_deadline(self)
    self.internal_deadline = DeadlineCalculator.internal_deadline(self)
    self.external_deadline = DeadlineCalculator.external_deadline(self)
  end

  def set_managing_team
    # For now, we just automatically assign cases to DACU.
    self.managing_team = BusinessUnit.dacu_bmt
    self.managing_assignment.state = 'accepted'
  end

  def set_number
    self.number = next_number
  end

  def next_number
    "%s%03d" % [
      received_date.strftime("%y%m%d"),
      CaseNumberCounter.next_for_date(received_date)
    ]
  end

  def process_uploaded_request_files
    if uploading_user.nil?
      # I really don't feel comfortable with having this special snowflake of a
      # attribute that only ever needs to be populated when creating a new case
      # that was sent by post.
      raise "Uploading user required for processing uploaded request files"
    end
    uploader = S3Uploader.new(self, uploading_user)
    uploader.process_files(uploaded_request_files, :request)
  end
end
#rubocop:enable Metrics/ClassLength
