# == Schema Information
#
# Table name: cases
#
#  id                :integer          not null, primary key
#  name              :string
#  email             :string
#  message           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  category_id       :integer
#  received_date     :date
#  postal_address    :string
#  subject           :string
#  properties        :jsonb
#  requester_type    :enum
#  number            :string           not null
#  date_responded    :date
#  outcome_id        :integer
#  refusal_reason_id :integer
#

# Required in production with it's eager loading and cacheing of classes.
require 'case_state_machine'

class Case < ApplicationRecord
  include Statesman::Adapters::ActiveRecordQueries

  acts_as_gov_uk_date :received_date, :date_responded,
                      validate_if: :received_not_in_the_future?

  scope :by_deadline, lambda {
    order("(properties ->> 'external_deadline')::timestamp with time zone ASC, id")
  }

  validates :name, :category, :message, :received_date, :subject, presence: true
  validates :email, presence: true, on: :create, if: -> { postal_address.blank? }
  validates :email, format: { with: /\A.+@.+\z/ }, if: -> { email.present? }
  validates :postal_address, presence: true, on: :create, if: -> { email.blank? }
  validates :subject, length: { maximum: 80 }
  validates :requester_type, presence: true

  validates_with ::ClosedCaseValidator

  serialize :exemption_ids, Array

  enum requester_type: {
      academic_business_charity: 'academic_business_charity',
      journalist: 'journalist',
      member_of_the_public: 'member_of_the_public',
      offender: 'offender',
      solicitor: 'solicitor',
      staff_judiciary: 'staff_judiciary',
      what_do_they_know: 'what_do_they_know'
    }

  jsonb_accessor :properties,
    escalation_deadline: :datetime,
    internal_deadline: :datetime,
    external_deadline: :datetime,
    trigger: [:boolean, default: false]

  belongs_to :category, required: true

  has_many :assignments, dependent: :destroy
  has_one :responder_assignment, -> { responding }, class_name: 'Assignment'
  has_one :responder, through: :responder_assignment, source: :user
  has_one :responding_team, -> { where("state != 'rejected'") }, through: :responder_assignment, source: :team
  has_one :managing_assignment, -> { managing }, class_name: 'Assignment'
  has_one :managing_team, through: :managing_assignment, source: :team
  has_many :transitions, class_name: 'CaseTransition', autosave: false
  has_many :attachments, class_name: 'CaseAttachment'
  belongs_to :outcome, class_name: 'CaseClosure::Outcome'
  belongs_to :refusal_reason, class_name: 'CaseClosure::RefusalReason'
  # belongs_to :exemption, class_name: 'CaseClosure::Exemption'
  has_and_belongs_to_many :exemptions, class_name: 'CaseClosure::Exemption', join_table: 'cases_exemptions'

  before_save :prevent_number_change
  before_create :set_deadlines, :set_number, :set_managing_team
  after_update :set_deadlines

  delegate :current_state, :available_events, to: :state_machine

  CaseStateMachine.states.each do |state|
    define_method("#{state}?") { current_state == state }
  end


  def self.search(term)
    where('lower(name) LIKE ?', "%#{term.downcase}%")
  end

  def prevent_number_change
    raise StandardError.new('number is immutable') if number_changed?
  end

  def triggerable?
    category.abbreviation == 'FOI' && !trigger?
  end

  def requires_approval?
    category.abbreviation == 'GQ' || trigger?
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

  def state_machine
    @state_machine ||= ::CaseStateMachine.new(
      self,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end

  def assign_responder(current_user, responding_team)
    managing_team = current_user.managing_team_roles.first.team
    state_machine.assign_responder current_user,
                                   managing_team,
                                   responding_team
  end

  def responder_assignment_rejected(current_user,
                                    responding_team,
                                    message)
    state_machine.reject_responder_assignment! current_user,
                                               responding_team,
                                               message
  end

  def responder_assignment_accepted(current_user, responding_team)
    state_machine.accept_responder_assignment!(current_user, responding_team)
  end

  def add_responses(current_user, responses)
    self.attachments << responses
    filenames = responses.map(&:filename)
    state_machine.add_responses!(current_user, responding_team, filenames)
  end

  def remove_response(current_user, attachment)
    attachment.destroy!
    state_machine.remove_response current_user,
                                  responding_team,
                                  attachment.filename,
                                  self.reload.attachments.size
  end

  def response_attachments
    attachments.select(&:response?)
  end

  def respond(current_user)
    state_machine.respond!(current_user, responding_team)
    responder_assignment.destroy
  end

  def close(current_user)
    state_machine.close!(current_user, managing_team)
  end

  def received_not_in_the_future?
    if received_date.present? && self.received_date > Date.today

      errors.add(
          :received_date,
          I18n.t('activerecord.errors.models.case.attributes.received_date.not_in_future')
      )
      true
    else
      false
    end
  end

  def attachments_dir(attachment_type)
    "#{id}/#{attachment_type}"
  end

  def who_its_with
    if responding_team.present?
      responding_team.name
    else
      managing_team.name
    end
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

  def has_ncnd_exemption?
    exemptions.select{ |ex| ex.ncnd? }.any?
  end

  private

  def set_deadlines
    self.escalation_deadline = DeadlineCalculator.escalation_deadline(self) if triggerable?
    self.internal_deadline = DeadlineCalculator.internal_deadline(self) if requires_approval?
    self.external_deadline = DeadlineCalculator.external_deadline(self)
  end

  def set_managing_team
    # For now, we just automatically assign cases to DACU.
    self.managing_team = Team.managing.find_by!(name: 'DACU')
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
end
