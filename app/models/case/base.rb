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

class Case::Base < ApplicationRecord
  TRIGGER_WORKFLOWS = %w[trigger full_approval].freeze
  CREATE_EVENT = "create".freeze

  def self.searchable_fields_and_ranks
    {
      name: "A",
      number: "A",
      responding_team_name: "B",
      subject: "C",
      message: "D",
    }
  end

  def self.searchable_document_tsvector
    "document_tsvector"
  end

  include Searchable
  include Warehousable

  self.table_name = :cases

  default_scope { where(deleted: false) }

  attr_accessor :flag_for_disclosure_specialists, :uploaded_request_files, :request_amends_comment, :upload_comment, :draft_compliant, :message_text, :number_to_link

  jsonb_accessor :properties,
                 date_draft_compliant: :date,
                 has_pit_extension: [:boolean, { default: false }]

  attr_reader :deadline_calculator

  acts_as_gov_uk_date :date_responded,
                      :date_draft_compliant,
                      :external_deadline,
                      :received_date,
                      validate_if: :received_in_acceptable_range?

  scope :by_deadline, lambda {
    select("\"cases\".*, (cases.properties ->> 'external_deadline')::timestamp with time zone, cases.id")
      .order(Arel.sql("(cases.properties ->> 'external_deadline')::timestamp with time zone ASC, cases.id"))
  }
  scope :by_last_transitioned_date, -> { reorder(last_transitioned_at: :desc) }
  scope :most_recent_first, -> { reorder(Arel.sql("(cases.properties ->> 'external_deadline')::timestamp with time zone DESC, cases.id")) }

  scope :opened, -> { where.not(current_state: "closed") }
  scope :not_icos, -> { where.not(type: ["Case::ICO::FOI", "Case::ICO::SAR"]) }

  scope :not_closed_or_responded, -> { where.not(current_state: %i[responded closed]) }

  scope :icos_not_responded_or_closed, -> { where(type: ["Case::ICO::FOI", "Case::ICO::SAR"]).not_closed_or_responded }

  scope :presented_as_open, -> { opened.not_icos.or(icos_not_responded_or_closed) }

  scope :closed, -> { where(current_state: "closed") }
  scope :presented_as_closed, -> { where(current_state: "closed").or(where(type: ["Case::ICO::FOI", "Case::ICO::SAR"], current_state: %i[responded closed])) }
  scope :standard_foi, -> { where(type: "Case::FOI::Standard") }
  scope :ico_appeal, ->   { where(type: ["Case::ICO::FOI", "Case::ICO::SAR"]) }
  scope :overturned_ico, lambda {
                           where(type: ["Case::OverturnedICO::FOI",
                                        "Case::OverturnedICO::SAR"])
                         }

  scope :non_offender_sar, -> { where(type: "Case::SAR::Standard") }
  scope :offender_sar, -> { where(type: "Case::SAR::Offender") }
  scope :offender_sar_complaint, -> { where(type: "Case::SAR::OffenderComplaint") }

  scope :with_teams, lambda { |teams|
    includes(:assignments)
      .where(assignments: { team: teams,
                            state: %w[pending accepted] })
  }
  scope :not_with_teams, lambda { |teams|
    where.not(id: Case::Base.with_teams(teams).pluck(:id))
  }

  scope :in_states, ->(states) { where(current_state: states) }

  scope :with_user, lambda { |*users, states: %w[pending accepted]|
    joins(:assignments)
      .where(assignments: { user_id: users.map(&:id),
                            state: states })
  }

  scope :in_open_state, -> { where.not(current_state: %w[responded closed]) }
  scope :in_open_or_responded_state, -> { where.not(current_state: %w[closed]) }
  scope :in_stop_the_clock_state, -> { where(current_state: %w[stopped]) }

  scope :accepted, lambda {
                     joins(:assignments)
                          .where(assignments: { state: %w[accepted] })
                   }
  scope :accepted_responding, lambda {
                                joins(:assignments)
                                    .where(assignments: { state: %w[accepted], role: "responding" })
                              }
  scope :unaccepted, lambda {
                       joins(:assignments)
                            .where.not(assignments: { state: "accepted" })
                     }
  scope :pending_accepted, -> { joins(:assignments).where(assignments: { state: %w[pending accepted] }) }

  scope :waiting_to_be_accepted, lambda { |*teams|
    includes(:assignments)
      .where(assignments: { team_id: teams.map(&:id),
                            state: %w[pending] })
  }

  # cases that have ever been flagged for approval
  scope :flagged_for_approval, lambda { |*teams|
    joins(:assignments).merge(Assignment.flagged_for_approval(teams))
  }
  scope :trigger, -> { where(workflow: TRIGGER_WORKFLOWS) }
  scope :non_trigger, -> { where.not(workflow: TRIGGER_WORKFLOWS) }

  scope :in_time, lambda {
    where(
      "CASE WHEN current_state = 'closed' THEN date_responded <= (properties->>'external_deadline')::date ELSE ? <= properties->>'external_deadline' END",
      Time.zone.today,
    )
  }
  scope :late, lambda {
    where(
      "CASE WHEN current_state = 'closed' THEN date_responded > (properties->>'external_deadline')::date ELSE ? > properties->>'external_deadline' END",
      Time.zone.today,
    )
  }

  scope :high_profile, lambda {
    where(
      "properties->>'flag_as_high_profile'::text = ? ",
      true.to_s,
    )
  }

  scope :not_high_profile, lambda {
    where(
      "properties->>'flag_as_high_profile'::text = ? ",
      false.to_s,
    )
  }

  scope :dps_missing_data, lambda {
    where(
      "properties->>'flag_as_dps_missing_data'::text = ? ",
      true.to_s,
    )
  }

  scope :not_dps_missing_data, lambda {
    where(
      "properties->>'flag_as_dps_missing_data'::text = ? or properties->>'flag_as_dps_missing_data'::text is null",
      false.to_s,
    )
  }

  scope :partial_case, lambda {
    where(
      "properties->>'is_partial_case'::text = ? ",
      true.to_s,
    )
  }

  scope :not_partial_case, lambda {
    where(
      "properties->>'is_partial_case'::text = ? or properties->>'is_partial_case'::text is null",
      false.to_s,
    )
  }

  scope :appeal, -> { where("type=? OR type=?", "Case::FOI::TimelinessReview", "Case::FOI::ComplianceReview") }

  scope :with_exemptions, ->(exemption_ids) { includes(:cases_exemptions).where(cases_exemptions: { exemption_id: exemption_ids }) }

  scope :internal_review_compliance, -> { where(type: "Case::FOI::ComplianceReview") }
  scope :internal_review_timeliness, -> { where(type: "Case::FOI::TimelinessReview") }
  scope :deadline_within, ->(from_date, to_date) { where("properties->>'external_deadline' BETWEEN ? AND ?", from_date, to_date) }
  scope :internal_deadline_within, ->(from_date, to_date) { where("properties->>'internal_deadline' BETWEEN ? AND ?", from_date, to_date) }

  scope :sar_ir_compliance, -> { where(type: "Case::SAR::InternalReview").where("properties->>'sar_ir_subtype' = 'compliance'") }
  scope :sar_ir_timeliness, -> { where(type: "Case::SAR::InternalReview").where("properties->>'sar_ir_subtype' = 'timeliness'") }

  validates :creator, presence: true
  scope :soft_deleted, -> { where(deleted: true) }

  scope :updated_since, ->(date) { where("updated_at >= ?", date) }

  validates :current_state, presence: true, on: :update
  validate :validate_email_format
  validates :received_date, presence: true
  validates :type, presence: true, exclusion: { in: %w[Case], message: "Case type cannot be blank" }
  validates :workflow, inclusion: { in: %w[standard trigger full_approval], message: "invalid" }

  validate :validate_related_cases
  validates_associated :case_links

  validates_with ::RespondedCaseValidator
  validates_with ::ClosedCaseValidator

  validates :reason_for_deletion, presence: { if: -> { deleted } }

  has_many :assignments, inverse_of: :case, dependent: :destroy, foreign_key: :case_id

  has_many :teams, through: :assignments

  has_one :warehouse_case_report,
          class_name: "Warehouse::CaseReport",
          foreign_key: :case_id,
          autosave: false,
          dependent: :destroy

  has_one :managing_assignment,
          -> { managing },
          class_name: "Assignment",
          foreign_key: :case_id

  has_one :retention_schedule,
          foreign_key: :case_id,
          class_name: "RetentionSchedule"

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
          class_name: "Assignment",
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
           class_name: "Assignment",
           foreign_key: :case_id

  has_many :approvers,
           through: :approver_assignments,
           source: :user

  has_many :approving_teams,
           through: :approver_assignments,
           source: :team

  has_many :approving_team_users,
           through: :approving_teams,
           source: :users

  has_many :transitions,
           class_name: "CaseTransition",
           foreign_key: :case_id,
           inverse_of: :case,
           autosave: false,
           dependent: :destroy do
             def most_recent
               where(most_recent: true).first
             end
           end
  has_many :message_transitions,
           -> { messages },
           class_name: "CaseTransition",
           foreign_key: :case_id

  has_many :responded_transitions,
           -> { responded },
           class_name: "CaseTransition",
           foreign_key: :case_id

  has_many :assign_responder_transitions,
           -> { where(event: CaseTransition::ASSIGN_RESPONDER_EVENT) },
           class_name: "CaseTransition",
           foreign_key: :case_id

  has_many :users_transitions_trackers,
           class_name: "CasesUsersTransitionsTracker",
           foreign_key: :case_id

  has_many :attachments, -> { order(id: :desc) },
           class_name: "CaseAttachment",
           foreign_key: :case_id,
           inverse_of: :case,
           dependent: :destroy

  belongs_to :late_team, class_name: "BusinessUnit"

  belongs_to :team_responsible_for_outcome, class_name: "BusinessUnit"

  belongs_to :outcome, class_name: "CaseClosure::Outcome"

  belongs_to :appeal_outcome, class_name: "CaseClosure::AppealOutcome"

  belongs_to :refusal_reason, class_name: "CaseClosure::RefusalReason"

  belongs_to :info_held_status, class_name: "CaseClosure::InfoHeldStatus"

  # A Case creator has no bearing on what the user can do with a Case.
  # Abilities are defined via config/state_machine/* and related predicates
  belongs_to :creator, class_name: "User", foreign_key: :user_id

  has_many :cases_exemptions,
           class_name: "CaseExemption",
           foreign_key: :case_id

  has_many :exemptions,
           class_name: "CaseClosure::Exemption",
           through: "cases_exemptions",
           foreign_key: :case_id

  has_many :cases_outcome_reasons,
           class_name: "CaseOutcomeReason",
           foreign_key: :case_id

  has_many :outcome_reasons,
           class_name: "CaseClosure::OutcomeReason",
           through: "cases_outcome_reasons",
           foreign_key: :case_id

  has_many :case_links,
           -> { readonly },
           class_name: "LinkedCase",
           foreign_key: :case_id do
    def <<(_record)
      raise ActiveRecord::ActiveRecordError, "association is readonly"
    end

    def create(_attributes = {})
      raise ActiveRecord::ActiveRecordError, "association is readonly"
    end

    def create!(_attributes = {})
      raise ActiveRecord::ActiveRecordError, "association is readonly"
    end
  end

  has_many :linked_cases,
           through: :case_links,
           class_name: "Case::Base",
           foreign_key: :case_id

  has_many :related_case_links,
           -> { related },
           class_name: "LinkedCase",
           foreign_key: :case_id
  has_many :related_cases,
           through: :related_case_links,
           source: :linked_case,
           after_remove: :delete_reverse_links

  has_many :original_case_links,
           -> { original },
           class_name: "LinkedCase",
           foreign_key: :case_id

  has_many :original_cases,
           through: :original_case_links,
           source: :linked_case,
           after_remove: :delete_reverse_links

  has_many :original_appeal_and_related_case_links,
           -> { related_and_appeal },
           class_name: "LinkedCase",
           foreign_key: :case_id

  has_many :original_appeal_and_related_cases,
           through: :original_appeal_and_related_case_links,
           source: :linked_case

  after_initialize do
    self.workflow = default_workflow if workflow.nil?
    @deadline_calculator = create_deadline_calculator
  end

  before_create :set_initial_state,
                :set_number,
                :set_managing_team,
                :set_deadlines
  before_update :update_deadlines
  before_save :prevent_number_change,
              :trigger_reindexing

  after_create :create_init_transition, :trigger_reindexing_after_creation

  delegate :available_events, to: :state_machine

  include CaseStates

  # @note Magic methods for all available Case states such as unassigned?,
  #   pending_dacu_clearance?, etc
  ConfigurableStateMachine::Machine.states.each do |state|
    define_method("#{state}?") { current_state == state }
  end

  def create_init_transition
    attrs = {
      case_id: id,
      event: CREATE_EVENT,
      to_state: current_state,
      to_workflow: workflow,
      sort_key: CaseTransition.next_sort_key(self),
      most_recent: true,
      acting_user: creator,
      acting_team: managing_team,
    }
    CaseTransition.create!(attrs)
  end

  def self.state_machine_name
    type_abbreviation.downcase
  end

  def self.permitted_states
    ConfigurableStateMachine::Manager.instance.permitted_states(type_abbreviation.downcase.to_sym)
  end

  def self.factory(_type)
    raise NotImplementedError, "Case type must implement self.factory"
  end

  # Once a case has been anonymised we forbid any further updates.
  # Note destroy/delete will still work.
  def readonly?
    closed? && !!retention_schedule.try(:anonymised?)
  end

  def editable?
    !readonly?
  end

  def to_csv
    CSVExporter.new(self).to_csv
  end

  def upload_response_groups
    CaseAttachmentUploadGroupCollection.new(self, attachments.response, :responder)
  end

  def upload_request_groups
    CaseAttachmentUploadGroupCollection.new(self, attachments.request, :manager)
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

  def team_for_assigned_user(user, role)
    TeamFinderService.new(self, user, role).team_for_assigned_user
  end

  def team_for_unassigned_user(user, role)
    TeamFinderService.new(self, user, role).team_for_unassigned_user
  end

  def team_for_user(user, role)
    TeamFinderService.new(self, user, role).team_for_user
  end

  def permitted_teams
    assignments.where(state: %i[accepted pending]).map(&:team)
  end

  def allow_event?(user, event)
    state_machine.permitted_events(user.id).include?(event)
  end

  def prevent_number_change
    raise StandardError, "number is immutable" if number_changed?
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

  # +date_draft_compliant+ was added February 2019, historical
  # Cases do not have draft timeliness information set and
  # therefore cannot be considered to be in/out of draft deadline
  def within_draft_deadline?
    return if date_draft_compliant.blank?

    date_draft_compliant <= internal_deadline
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

  def prepare_for_respond
    @preparing_for_respond = true
  end

  def prepared_for_respond?
    @preparing_for_respond == true
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
    responded_transitions.any?
  end

  def responded_late?
    date_responded.present? && (date_responded > external_deadline)
  end

  def responded_in_time?
    return false unless closed_for_reporting_purposes?

    !date_responded.nil? && date_responded <= external_deadline
  end

  # Note use of +responded?+ as guard to prevent exceptions
  # thrown by business_unit_responded_in_time? from arising
  def response_in_target?
    responded? && business_unit_responded_in_time?
  end

  # determines whether or not an individual BU responded to a case in time, measured
  # from the date the case was assigned to the business unit to the time the case was marked as responded.
  # Note that the time limit is different for trigger cases (the internal time limit) than for non trigger
  # (the external time limit)
  #
  def business_unit_responded_in_time?
    if responded_transitions.any?
      responding_team_assignment_date = assign_responder_transitions.last.created_at.to_date
      responding_date = responded_transitions.last.created_at.to_date
      internal_deadline = @deadline_calculator
                              .internal_deadline_for_date(correspondence_type, responding_team_assignment_date)
      internal_deadline >= responding_date
    else
      raise ArgumentError, "Cannot call ##{__method__} on a case without a response (Case #{number})"
    end
  end

  def business_unit_already_late?
    if responded_transitions.any?
      raise ArgumentError, "Cannot call ##{__method__} on a case for which the response has been sent"
    else
      responding_team_assignment_date = assign_responder_transitions.last&.created_at&.to_date || received_date
      internal_deadline = @deadline_calculator.business_unit_deadline_for_date(responding_team_assignment_date)
      internal_deadline < Time.zone.today
    end
  end

  def default_clearance_team
    case_type = "#{type_abbreviation.downcase}_cases"
    team_code = Settings.__send__(case_type).default_clearance_team
    Team.find_by code: team_code
  end

  def responded_in_time_for_stats_purposes?
    if flagged?
      flagged_case_responded_to_in_time_for_stats_purposes?
    else
      responded_in_time?
    end
  end

  def already_late?
    Date.current > external_deadline
  end

  def num_days_late
    days = @deadline_calculator.days_late(
      external_deadline,
      benchmark_date_value_for_days_metrics,
    )
    days.positive? ? days : nil
  end

  def num_days_late_against_original_deadline
    if original_external_deadline.present?
      days = @deadline_calculator.days_late(
        original_external_deadline,
        benchmark_date_value_for_days_metrics,
      )
      days.positive? ? days : nil
    end
  end

  def num_days_taken
    days = @deadline_calculator.days_taken(
      received_date,
      benchmark_date_value_for_days_metrics,
    )
    days.positive? ? days : nil
  end

  def num_days_taken_after_extension
    the_date_being_extended = find_most_recent_action_timing_for_pit_extension
    if the_date_being_extended.present?
      days = @deadline_calculator.days_taken(
        the_date_being_extended,
        benchmark_date_value_for_days_metrics,
      )
      days.positive? ? days : nil
    end
  end

  def current_team_and_user
    CurrentTeamAndUserService.new(self)
  end

  def responding_team_name
    responding_team&.name
  end

  def approver_assignment_for(team)
    approver_assignments.where(team:).first
  end

  def non_default_approver_assignments
    approver_assignments.where.not(team: default_team_service.approving_team).sort { |a, b| a.team.name <=> b.team.name }
  end

  def transition_tracker_for_user(user)
    users_transitions_trackers.where(user:).singular_or_nil
  end

  def format_workflow_class_name(type_template, type_workflow_template)
    if workflow.present?
      type_workflow_template % ({ type: type_abbreviation, workflow: })
    else
      sprintf(type_template, type: type_abbreviation)
    end
  end

  def is_internal_review?
    is_a?(Case::FOI::InternalReview)
  end

  def type_abbreviation
    # This string is used when constructing paths or methods in other parts of
    # the system. Ensure that it does not come from a user-supplied parameter,
    # and does not contain special chars like slashes, etc.
    self.class.type_abbreviation
  end

  def correspondence_type
    # CorrespondenceType.find_by_abbreviation! is overloaded to look in a
    # global cache of all (probably 6) correspondence types
    CorrespondenceType.find_by_abbreviation! type_abbreviation.parameterize.underscore.upcase
  end
  # rubocop:enable Rails/DynamicFindBy

  # Override this method if you want to make this correspondence type
  # assignable by the same business units as another correspondence type. e.x.
  # ICO Overturned FOIs can be assigned to the same business units as FOIs
  def correspondence_type_for_business_unit_assignment
    correspondence_type
  end

  def is_foi?
    type_abbreviation == "FOI"
  end

  def is_sar?
    type_abbreviation == "SAR"
  end

  def is_sar_internal_review?
    type_abbreviation == "SAR_INTERNAL_REVIEW"
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

  def assigned_disclosure_specialist!
    ass = assignments.approving.accepted.detect { |a| a.team_id == BusinessUnit.dacu_disclosure.id }
    raise "No assigned disclosure specialist" if ass.nil? || ass.user.nil?

    ass.user
  end

  def assigned_disclosure_specialist
    assignments
      .approving
      .accepted
      .detect { |a| a.team_id == BusinessUnit.dacu_disclosure.id }
      &.user
  end

  def assigned_press_officer!
    ass = assignments.approving.accepted.detect { |a| a.team_id == BusinessUnit.press_office.id }
    raise "No assigned press officer" if ass.nil? || ass.user.nil?

    ass.user
  end

  def assigned_private_officer!
    ass = assignments.approving.accepted.detect { |a| a.team_id == BusinessUnit.private_office.id }
    raise "No assigned private officer" if ass.nil? || ass.user.nil?

    ass.user
  end

  # Caseworker officer is blank for non-trigger and
  # always a disclosure specialist for trigger cases as requested by
  # London team.
  def casework_officer
    casework_officer_user&.full_name
  end

  def casework_officer_user
    if trigger?
      assigned_disclosure_specialist
    end
  end

  def requires_flag_for_disclosure_specialists?
    true
  end

  def closed_for_reporting_purposes?
    has_responded?
  end

  # don't know why, but adding external deadline into the list of dates acting as gov uk seems to remove
  # external_deadline= method, so re-adding it here
  def external_deadline=(date)
    self[:external_deadline] = date
  end

  def current_team_and_user_resolver
    CurrentTeamAndUser::Base.new(self)
  end

  def extended_for_pit?
    has_pit_extension?
  end

  def extend_pit_deadline!(new_deadline)
    update!(
      external_deadline: new_deadline,
      has_pit_extension: true,
    )
  end

  def remove_pit_deadline!(initial_deadline)
    update!(
      external_deadline: initial_deadline,
      has_pit_extension: false,
    )
  end

  def trigger?
    TRIGGER_WORKFLOWS.include?(workflow)
  end

  # @note A flagged case can be assumed to be a trigger case
  def trigger_status
    flagged? ? "trigger" : "non_trigger"
  end

  def has_responded?
    current_state == "closed" || current_state == "responded"
  end

  # predicate methods
  #
  def foi? = false
  def foi_standard? = false
  def foi_ir_timeliness? = false
  def foi_ir_compliance? = false
  def sar? = false
  def ico? = false
  def overturned_ico? = false
  def overturned_ico_sar? = false
  def overturned_ico_foi? = false
  def type_of_offender_sar? = false
  def offender_sar? = false
  def offender_sar_complaint? = false
  def sar_internal_review? = false
  def all_holidays? = false
  def rejected? = false

  def default_managing_team
    BusinessUnit.dacu_bmt
  end

  def validate_email_format
    if email.present? && email !~ /\A.+@.+\z/
      errors.add(
        :email,
        :invalid,
      )
    end
  end

  def stoppable?
    false
  end

  def restartable?
    false
  end

private

  def create_deadline_calculator
    if self.class.respond_to?(:type_abbreviation)
      klass = ::DeadlineCalculator.const_get(
        correspondence_type.deadline_calculator_class,
      )
      klass.new(self)
    end
  end

  def identifier
    name.sub(/\sname\s?\d{0,3}$/, "")
  end

  def default_workflow
    "standard"
  end

  def indexable_fields
    @indexable_fields ||= self.class.searchable_fields_and_ranks.keys.map(&:to_s)
  end

  def received_in_acceptable_range?
    if new_record? || received_date_changed?
      validate_received_date
    end
    if date_draft_compliant.present?
      validate_date_draft_compliant
    end
  end

  def validate_received_date
    if received_date.present? && received_date > Time.zone.today
      errors.add(
        :received_date,
        I18n.t("activerecord.errors.models.case.attributes.received_date.not_in_future"),
      )
    elsif received_date.present? && received_date < Time.zone.today - 1.year
      unless type_of_offender_sar?
        errors.add(
          :received_date,
          I18n.t("activerecord.errors.models.case.attributes.received_date.past"),
        )
      end
    end
    errors[:received_date].any?
  end

  def validate_date_draft_compliant
    if date_draft_compliant < received_date
      errors.add(
        :date_draft_compliant,
        I18n.t("activerecord.errors.models.case.attributes.date_draft_compliant.before_received"),
      )
    elsif date_draft_compliant > Time.zone.today
      errors.add(
        :date_draft_compliant,
        I18n.t("activerecord.errors.models.case.attributes.date_draft_compliant.not_in_future"),
      )
    elsif date_responded.present? && date_draft_compliant > date_responded
      unless sar_internal_review?
        errors.add(
          :date_draft_compliant,
          I18n.t("activerecord.errors.models.case.attributes.date_draft_compliant.after_date_responded"),
        )
      end
    end
    errors[:date_draft_compliant].any?
  end

  def received_date_changed?
    received_date != received_date_was
  end

  def set_initial_state
    self.current_state = state_machine.current_state
    self.last_transitioned_at = Time.zone.now
  end

  def set_deadlines
    # Deadlines should really get their own table and be parameterised on:
    #   correspondence_type_id
    #   name - (e.g. internal, external, final)
    #   days - number of days from the from_date
    #   from date - the date to calculate from, e.g. created, received, day_after_created, day_after_received, external_deadline
    #   business/calendar days - whether to calculate in business days or calendar days
    self.escalation_deadline = @deadline_calculator.escalation_deadline
    self.internal_deadline = @deadline_calculator.internal_deadline
    self.external_deadline = @deadline_calculator.external_deadline
  end

  def update_deadlines
    if changed.include?("received_date") && !extended_for_pit?
      self.internal_deadline = @deadline_calculator.internal_deadline
      self.external_deadline = @deadline_calculator.external_deadline
    end
  end

  def set_managing_team
    # For now, we just automatically assign cases to DACU.
    self.managing_team = default_managing_team
    managing_assignment.state = "accepted"
  end

  def set_number
    self.number = next_number
  end

  def next_number
    sprintf("%s%03d", received_date.strftime("%y%m%d"), CaseNumberCounter.next_for_date(received_date))
  end

  # NOTE: When creating a case Delivery Method: Post
  # allows the user to upload documents (presumably letters)
  # which are converted to PDF files via a delayed job
  def process_uploaded_request_files
    if creator.nil?
      raise "Creator user required for processing uploaded request files"
    end

    uploader = S3Uploader.new(self, creator)
    uploader.process_files(uploaded_request_files, :request)
  end

  def trigger_reindexing
    if (changed & indexable_fields).any? && id.present?
      self.dirty = true
      SearchIndexUpdaterJob.set(wait: 10.seconds).perform_later(id)
    end
  end

  def trigger_reindexing_after_creation
    SearchIndexUpdaterJob.set(wait: 10.seconds).perform_later(id)
  end

  def validate_related_cases
    related_cases.each do |kase|
      validate_case_link(:related, kase, :related_cases)
    end
  end

  def validate_case_link(type, linked_case, attribute)
    linkable = CaseLinkTypeValidator.classes_can_be_linked_with_type?(
      klass: self.class.to_s,
      linked_klass: linked_case.class.to_s,
      type:,
    )

    unless linkable
      case_class_name = I18n.t("cases.types.#{self.class}")
      linked_class_name = I18n.t("cases.types.#{linked_case.class}")
      errors.add(
        attribute,
        :wrong_type,
        message: I18n.t("activerecord.errors.models.linked_case.wrong_type",
                        type:,
                        case_class: case_class_name,
                        linked_case_class: linked_class_name),
      )
    end
  end

  def find_most_recent_action_timing_for_pit_extension
    if has_pit_extension?
      most_recent_extension = transitions
      .where(event: %w[extend_for_pit])
      .order(id: :desc)
      .first
      most_recent_extension.nil? ? nil : most_recent_extension.created_at.to_date
    end
  end

  def benchmark_date_value_for_days_metrics
    date_responded.nil? ? Time.zone.today : date_responded
  end

  def delete_reverse_links(related_case)
    # When the related cases are managed by collections way, the after_destroy callback
    # won't be called as the object is deleted directly. We introduce this call back
    # to make sure the reverse link is removed.
    reverse_links = LinkedCase.where(case_id: related_case.id, linked_case_id: id)
    reverse_links.each(&:delete)
  end
end
# rubocop:enable Metrics/ClassLength
