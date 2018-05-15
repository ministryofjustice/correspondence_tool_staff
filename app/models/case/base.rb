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
#  workflow             :string           default("standard")
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

#rubocop:disable Metrics/ClassLength
class Case::Base < ApplicationRecord

  TRIGGER_WORKFLOWS = ['trigger', 'full_approval'].freeze

  def self.searchable_fields_and_ranks
    {
        name:                 'A',
        number:               'A',
        responding_team_name: 'B',
        subject:              'C',
        message:              'D',
    }
  end

  def self.searchable_document_tsvector
    'document_tsvector'
  end

  include Searchable

  self.table_name = :cases

  default_scope { where( deleted: false) }

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

  scope :opened, ->       { where.not(current_state: 'closed') }
  scope :closed, ->       { where(current_state: 'closed').order(last_transitioned_at: :desc) }
  scope :standard_foi, -> { where(type: 'Case::FOI::Standard') }

  scope :with_teams, -> (teams) do
    includes(:assignments)
      .where(assignments: { team: teams,
                            state: ['pending', 'accepted']})
  end
  scope :not_with_teams, -> (teams) do
    where.not(id: Case::Base.with_teams(teams).pluck(:id))
  end

  scope :in_states, -> (states) { where(current_state: states) }

  scope :with_user, ->(*users, states: ['pending', 'accepted']) do
    joins(:assignments)
      .where(assignments: { user_id: users.map { |u| u.id },
                            state: states})
  end

  scope :in_open_state, -> { where. not(current_state: %w[responded closed] ) }

  scope :accepted, -> { joins(:assignments)
                          .where(assignments: {state: ['accepted']} ) }
  scope :unaccepted, -> { joins(:assignments)
                            .where.not(assignments: {state: 'accepted'} ) }
  scope :pending_accepted, -> { joins(:assignments).where(assignments: {state: %w[pending accepted] } ) }

  scope :waiting_to_be_accepted, ->(*teams) do
    includes(:assignments)
      .where(assignments: { team_id: teams.map { |t| t.id },
                            state: ['pending']})
  end

  # cases that have ever been flagged for approval
  scope :flagged_for_approval, ->(*teams) do
    joins(:assignments)
      .where(assignments: { team_id: teams.map(&:id), role: 'approving' })
  end
  scope :trigger, -> { where(workflow: TRIGGER_WORKFLOWS) }
  scope :non_trigger, -> { where.not(workflow: TRIGGER_WORKFLOWS) }

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

  scope :appeal, -> { where('type=? OR type=?', 'Case::FOI::TimelinessReview', 'Case::FOI::ComplianceReview' )}

  scope :with_exemptions, ->(exemption_ids) { includes(:cases_exemptions).where(cases_exemptions: {exemption_id: exemption_ids} ) }

  scope :internal_review_compliance, -> { where(type: 'Case::FOI::ComplianceReview')}
  scope :internal_review_timeliness, -> { where(type: 'Case::FOI::TimelinessReview')}
  scope :deadline_within, -> (from_date, to_date) { where("properties->>'external_deadline' BETWEEN ? AND ?", from_date, to_date) }
  validates :current_state, presence: true, on: :update

  validates :email, format: { with: /\A.+@.+\z/ }, if: -> { email.present? }
  validates_presence_of :received_date
  validates :subject, presence: true, length: { maximum: 100 }
  validates :type, presence: true, exclusion: { in: %w{Case}, message: "Case type can't be blank" }
  validates :workflow, inclusion: { in: %w{ standard trigger full_approval }, message: "invalid" }

  validates_with ::ClosedCaseValidator

  has_many :assignments, dependent: :destroy, foreign_key: :case_id

  has_many :teams, through: :assignments

  has_one :managing_assignment,
          -> { managing },
          class_name: 'Assignment',
          foreign_key: :case_id

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
          class_name: 'Assignment',
          foreign_key: :case_id

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
           class_name: 'Assignment',
           foreign_key: :case_id

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
           foreign_key: :case_id,
           autosave: false,
           dependent: :destroy do
              def most_recent
                where(most_recent: true).first
              end
           end
  has_many :message_transitions,
           -> { messages },
           class_name: 'CaseTransition',
           foreign_key: :case_id

  has_many :users_transitions_trackers,
           class_name: 'CasesUsersTransitionsTracker',
           foreign_key: :case_id

  has_many :responded_transitions, -> { responded },
           class_name: 'CaseTransition',
           foreign_key: :case_id

  has_many :attachments, -> { order(id: :desc) },
           class_name: 'CaseAttachment',
           foreign_key: :case_id,
           dependent: :destroy

  belongs_to :outcome, class_name: 'CaseClosure::Outcome'

  belongs_to :appeal_outcome, class_name: 'CaseClosure::AppealOutcome'

  belongs_to :refusal_reason, class_name: 'CaseClosure::RefusalReason'

  belongs_to :info_held_status, class_name: 'CaseClosure::InfoHeldStatus'

  has_many :cases_exemptions,
           class_name: 'CaseExemption',
           table_name: :cases_exemptions,
           foreign_key: :case_id

  has_many :exemptions,
            class_name: 'CaseClosure::Exemption',
            through: 'cases_exemptions',
            foreign_key: :case_id

  has_and_belongs_to_many :linked_cases,
                          class_name: 'Case::Base',
                          join_table: 'linked_cases',
                          foreign_key: :case_id,
                          association_foreign_key: :linked_case_id

  before_create :set_initial_state,
                :set_number,
                :set_managing_team,
                :set_deadlines
  before_update :update_deadlines
  before_save :prevent_number_change,
              :trigger_reindexing

  before_save do
    self.wokflow = 'standard' if workflow.nil?
  end



  delegate :available_events, to: :state_machine

  include CaseStates

  ConfigurableStateMachine::Machine.states.each do |state|
    define_method("#{state}?") { current_state == state }
  end

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

  def outside_escalation_deadline?
    !within_escalation_deadline?
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

  def flagged_for_all?
    flagged_for_disclosure_specialist_clearance? &&
      flagged_for_press_office_clearance? &&
      flagged_for_private_office_clearance?
  end

  def responded?
    transitions.where(event: 'respond').any?
  end

  def responded_in_time?
    return false unless closed?
    date_responded <= external_deadline
  end

  def default_clearance_team
    case_type = "#{type_abbreviation.downcase}_cases"
    team_code = Settings.__send__(case_type).default_clearance_team
    Team.find_by_code team_code
  end

  def responded_in_time_for_stats_purposes?
    if flagged?
      business_unit_responded_to_flagged_case_in_time?
    else
      responded_in_time?
    end
  end

  def already_late?
    Date.today > external_deadline
  end

  def current_team_and_user
    CurrentTeamAndUserService.new(self)
  end

  def responding_team_name
    responding_team&.name
  end

  def approver_assignment_for(team)
    approver_assignments.where(team: team).first
  end

  def non_default_approver_assignments
    approver_assignments.where.not(team: default_team_service.approving_team).sort{ |a,b| a.team.name <=> b.team.name }
  end

  def transition_tracker_for_user(user)
    users_transitions_trackers.where(user: user).singular_or_nil
  end

  def sync_transition_tracker_for_user(user)
    CasesUsersTransitionsTracker.sync_for_case_and_user(self, user)
  end

  def format_workflow_class_name(type_template, type_workflow_template)
    if workflow.present?
      type_workflow_template % {type: type_abbreviation, workflow: workflow}
    else
      type_template % {type: type_abbreviation}
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

  def remove_linked_case(linked_case)
    ActiveRecord::Base.transaction do

      self.linked_cases.destroy(linked_case)

      linked_case.linked_cases.destroy(self)

    end
  end

  def is_internal_review?
    self.is_a?(Case::FOI::InternalReview)
  end

  def type_abbreviation
    self.class.type_abbreviation
  end

  def correspondence_type
    @correspondence_type ||=
      CorrespondenceType.find_by!(abbreviation: type_abbreviation)
  end

  def is_foi?
    type_abbreviation == 'FOI'
  end

  def is_sar?
    type_abbreviation == 'SAR'
  end

  def deadline_calculator
    klass = DeadlineCalculator.const_get(
      correspondence_type.deadline_calculator_class
    )
    klass.new(self)
  end

  def set_workflow!(new_workflow_name)
    update!(workflow: new_workflow_name)
  end

  def mark_as_clean!
    update!(dirty: false)
  end

  def mark_as_dirty!
    update!(dirty: true)
  end

  def clean?
    !dirty?
  end

  def assigned_disclosure_specialist
    ass = assignments.approving.accepted.detect{ |a| a.team_id == BusinessUnit.dacu_disclosure.id }
    raise 'No assigned disclosure specialist' if ass.nil? || ass.user.nil?
    ass.user
  end

  def assigned_press_officer
    ass = assignments.approving.accepted.detect{ |a| a.team_id == BusinessUnit.press_office.id }
    raise 'No assigned press officer' if ass.nil? || ass.user.nil?
    ass.user
  end

  def assigned_private_officer
    ass = assignments.approving.accepted.detect{ |a| a.team_id == BusinessUnit.private_office.id }
    raise 'No assigned private officer' if ass.nil? || ass.user.nil?
    ass.user
  end



  private

  def indexable_fields
    @indexable_fields ||= self.class.searchable_fields_and_ranks.keys.map(&:to_s)
  end

  # determines whether or not the BU responded to flagged cases in time (NOT
  # whether the case was responded to in time!) calculated as the time between
  # the responding BU being assigned the case and the disclosure team approving
  # it.
  def business_unit_responded_to_flagged_case_in_time?
    responding_team_acceptance_date = transitions.where(
      event: 'assign_responder'
    ).last.created_at.to_date

    disclosure_approval_date = transitions.where(
      event: 'approve',
      acting_team_id: default_clearance_team.id
    ).last.created_at.to_date

    internal_deadline = deadline_calculator.internal_deadline_for_date(
      correspondence_type, responding_team_acceptance_date
    )

    internal_deadline >= disclosure_approval_date
  end

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
    elsif received_date.present? && self.received_date < Date.today - 1.year
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
    self.escalation_deadline = deadline_calculator.escalation_deadline
    self.internal_deadline = deadline_calculator.internal_deadline
    self.external_deadline = deadline_calculator.external_deadline
  end

  def update_deadlines
    if changed.include?('received_date')  && !extended_for_pit?
      self.internal_deadline = deadline_calculator.internal_deadline
      self.external_deadline = deadline_calculator.external_deadline
    end
  end

  def extended_for_pit?
    transitions.where(event: 'extend_for_pit').any?
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

  def trigger_reindexing
    if (self.changed & indexable_fields).any?
      self.dirty = true
      SearchIndexUpdaterJob.set(wait: 10.seconds).perform_later
    end
  end

end
#rubocop:enable Metrics/ClassLength
