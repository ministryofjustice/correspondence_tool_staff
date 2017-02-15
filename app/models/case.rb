# == Schema Information
#
# Table name: cases
#
#  id             :integer          not null, primary key
#  name           :string
#  email          :string
#  message        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  category_id    :integer
#  received_date  :date
#  postal_address :string
#  subject        :string
#  properties     :jsonb
#  number         :string           not null
#  requester_type :enum
#

# Required in production with it's eager loading and cacheing of classes.
require 'case_state_machine'


class Case < ApplicationRecord
  include Statesman::Adapters::ActiveRecordQueries

  acts_as_gov_uk_date :received_date,
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

  has_many :assignees, through: :assignments
  belongs_to :category, required: true
  has_many :assignments, dependent: :destroy
  has_many :transitions, class_name: 'CaseTransition', autosave: false
  has_many :attachments, class_name: 'CaseAttachment'

  before_save :prevent_number_change
  before_create :set_deadlines, :set_number
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

  def drafter
    assignees.select(&:drafter?).first
  end

  def drafter_assignment
    assignments.detect(&:drafter?)
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

  def state_machine
    @state_machine ||= ::CaseStateMachine.new(
      self,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end

  def create_assignment(attributes)
    assignment = self.assignments.create(attributes)
    if assignment.valid?
      event = case assignment.assignment_type
              when 'drafter' then :assign_responder
              end
      state_machine.send(event, assignment.assigner_id, assignment.assignee.id)
    end
    assignment
  end

  def responder_assignment_rejected(assignee_id, message, assignment_id)
    state_machine.reject_responder_assignment!(
      assignee_id,
      message,
      assignment_id
    )
  end

  def responder_assignment_accepted(assignee_id)
    state_machine.accept_responder_assignment!(assignee_id)
  end

  def add_responses(assignee_id, responses)
    self.attachments << responses
    filenames = responses.map(&:filename)
    state_machine.add_responses!(assignee_id, filenames)
  end

  def response_attachments
    attachments.select(&:response?)
  end

  def respond(current_user_id)
    state_machine.respond!(current_user_id)
    drafter_assignment.destroy
  end

  def close(current_user_id)
    state_machine.close!(current_user_id)
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
    "#{Digest::SHA1.hexdigest(id.to_s)}/#{attachment_type}"
  end

  def who_its_with
    if drafter_assignment.present?
      self.drafter.email
    else
      'DACU'
    end
  end

  private

  def set_deadlines
    self.escalation_deadline = DeadlineCalculator.escalation_deadline(self) if triggerable?
    self.internal_deadline = DeadlineCalculator.internal_deadline(self) if requires_approval?
    self.external_deadline = DeadlineCalculator.external_deadline(self)
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
