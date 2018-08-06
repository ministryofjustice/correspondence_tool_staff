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

  acts_as_gov_uk_date :received_date, :date_responded, :external_deadline,
                      validate_if: :received_in_acceptable_range?

  scope :by_deadline, -> {
    select("\"cases\".*, (properties ->> 'external_deadline')::timestamp with time zone, cases.id")
      .order("(properties ->> 'external_deadline')::timestamp with time zone ASC, cases.id")
  }
  scope :by_last_transitioned_date, -> { reorder(last_transitioned_at: :desc) }
  scope :most_recent_first, -> {reorder("(properties ->> 'external_deadline')::timestamp with time zone DESC, cases.id") }

  scope :opened, ->       { where.not(current_state: 'closed') }
  scope :closed, ->       { where(current_state: 'closed')}
  scope :closed_incl_responded_icos, -> { where(current_state: 'closed').or(where(type: ['Case::ICO::FOI', "Case::ICO::SAR"], current_state: [:responded, :closed])) }
  scope :standard_foi, -> { where(type: 'Case::FOI::Standard') }
  scope :ico_appeal, ->   { where(type: ['Case::ICO::FOI', 'Case::ICO::SAR'])}

  scope :non_offender_sar, -> { where(type: 'Case::SAR') }

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
  validates :type, presence: true, exclusion: { in: %w{Case}, message: "Case type can't be blank" }
  validates :workflow, inclusion: { in: %w{ standard trigger full_approval }, message: "invalid" }

  validate :validate_related_cases
  validates_associated :case_links

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

  has_many :case_links,
           -> { readonly },
           class_name: 'LinkedCase',
           foreign_key: :case_id do
    def <<(_record)
      raise ActiveRecord::ActiveRecordError.new("association is readonly")
    end

    def create(_attributes = {})
      raise ActiveRecord::ActiveRecordError.new("association is readonly")
    end

    def create!(_attributes = {})
      raise ActiveRecord::ActiveRecordError.new("association is readonly")
    end
  end
  has_many :linked_cases,
           through: :case_links,
           class_name: 'Case::Base',
           foreign_key: :case_id

  has_many :related_case_links,
           -> { related },
           class_name: 'LinkedCase',
           foreign_key: :case_id
  has_many :related_cases,
           through: :related_case_links,
           source: :linked_case


  after_initialize do
    self.workflow = default_workflow if self.workflow.nil?
  end

  before_create :set_initial_state,
                :set_number,
                :set_managing_team,
                :set_deadlines
  before_update :update_deadlines
  before_save :prevent_number_change,
              :trigger_reindexing

  # before_save do
  #   self.workflow = 'standard' if workflow.nil?
  # end


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

  def outcome_abbreviation
    outcome&.abbreviation
  end

  def outcome_abbreviation=(abbreviation)
    self.outcome = CaseClosure::Outcome.by_abbreviation(abbreviation)
  end

  def refusal_reason_abbreviation
    refusal_reason&.abbreviation
  end

  def refusal_reason_abbreviation=(abbreviation)
    self.refusal_reason = CaseClosure::RefusalReason.by_abbreviation(abbreviation)
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
    return false unless closed_for_reporting_purposes?
    date_responded <= external_deadline
  end

  # determines whether or not an individual BU responded to a case in time, measured
  # from the date the case was assigned to the business unit to the time the case was marked as responded.
  # Note that the time limit is different for trigger cases (the internal time limit) than for non trigger
  # (the external time limit)
  #
  def business_unit_responded_in_time?
    responding_transitions = transitions.where(event: 'respond')
    if responding_transitions.any?
      responding_team_assignment_date = transitions.where(event: 'assign_responder').last.created_at.to_date
      responding_transition = responding_transitions.last
      responding_date = responding_transition.created_at.to_date
      internal_deadline = deadline_calculator
                              .internal_deadline_for_date(correspondence_type, responding_team_assignment_date)
      internal_deadline >= responding_date
    else
      raise ArgumentError.new("Cannot call ##{__method__} on a case without a response (Case #{number})")
    end
  end

  def business_unit_already_late?
    if transitions.where(event: 'respond').any?
      raise ArgumentError.new("Cannot call ##{__method__} on a case for which the response has been sent")
    else
      responding_team_assignment_date = transitions.where(event: 'assign_responder').last.created_at.to_date
      internal_deadline = deadline_calculator.business_unit_deadline_for_date(responding_team_assignment_date)
      internal_deadline < Date.today
    end
  end

  def default_clearance_team
    case_type = "#{type_abbreviation.downcase}_cases"
    team_code = Settings.__send__(case_type).default_clearance_team
    Team.find_by_code team_code
  end

  def responded_in_time_for_stats_purposes?
    if flagged?
      flagged_case_responded_to_in_time_for_stats_purposes?
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

  def is_internal_review?
    self.is_a?(Case::FOI::InternalReview)
  end

  def type_abbreviation
    self.class.type_abbreviation
  end

  # Return the CorrespondenceType object for this case.
  #
  # The CorrespondenceType is determined by the class of this case, which must
  # define the method <tt>type_abbreviation</tt> as a class method. This must
  # match an abbreviation of an existing CorrespondenceType object.
  #
  # As this isn't expressed with Rails relationships, the CorrespondenceType
  # object is cached inside the case object. For environments where the
  # CorrespondenceType object can change you may need to reload this object to
  # ensure you have the latest. For example in tests, when expecting a
  # default_press_officer to be defined on the CorrespondenceType for this case.
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

  def requires_flag_for_disclosure_specialists?
    true
  end

  def closed_for_reporting_purposes?
    closed?
  end

  # don't know why, but adding external deadline into the list of dates acting as gov uk seems to remove
  # external_deadline= method, so re-adding it here
  def external_deadline=(date)
    self[:external_deadline] = date
  end

  # predicate methods
  #
  def foi?;                 false;  end
  def foi_standard?;        false;  end
  def foi_ir_timeliness?;   false;  end
  def foi_ir_compliance?;   false;  end
  def sar?;                 false;  end
  def ico?;                 false;  end
  def overturned_ico?;      false;  end
  def overturned_ico_sar?;  false;  end
  def overturned_ico_foi?;  false;  end


  private

  def default_workflow
    'standard'
  end

  def indexable_fields
    @indexable_fields ||= self.class.searchable_fields_and_ranks.keys.map(&:to_s)
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
    # Deadlines should really get their own table and be parameterised on:
    #   correspondence_type_id
    #   name - (e.g. internal, external, final)
    #   days - number of days from the from_date
    #   from date - the date to calculate from, e.g. created, received, day_after_created, day_after_received, external_deadline
    #   business/calendar days - whether to calculate in business days or calendar days
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

  def validate_related_cases
    self.related_cases.each do |kase|
      validate_case_link(:related, kase, :related_cases)
    end
  end

  def validate_case_link(type, linked_case, attribute)
    if not CaseLinkTypeValidator.classes_can_be_linked_with_type?(
             klass: self.class.to_s,
             linked_klass: linked_case.class.to_s,
             type: type,
           )

      case_class_name = I18n.t("cases.types.#{self.class}")
      linked_class_name = I18n.t("cases.types.#{linked_case.class}")
      errors.add(
        attribute,
        :wrong_type,
        message: I18n.t('activerecord.errors.models.linked_case.wrong_type',
                        type: type,
                        case_class: case_class_name,
                        linked_case_class: linked_class_name)
      )

    end
  end
end
#rubocop:enable Metrics/ClassLength
