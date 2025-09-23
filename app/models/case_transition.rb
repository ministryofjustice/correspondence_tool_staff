# == Schema Information
#
# Table name: case_transitions
#
#  id             :integer          not null, primary key
#  event          :string
#  to_state       :string           not null
#  metadata       :jsonb
#  sort_key       :integer          not null
#  case_id        :integer          not null
#  most_recent    :boolean          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  acting_user_id :integer
#  acting_team_id :integer
#  target_user_id :integer
#  target_team_id :integer
#  to_workflow    :string
#

class CaseTransition < ApplicationRecord
  include Warehousable

  ASSIGN_RESPONDER_EVENT = "assign_responder".freeze

  belongs_to :case,
             inverse_of: :transitions,
             class_name: "Case::Base"

  # This list should be bigger, but don't have time or inclination to move all event names here (yet)
  EXTEND_FOR_PIT_EVENT = "extend_for_pit".freeze
  REMOVE_PIT_EXTENSION_EVENT = "remove_pit_extension".freeze
  EXTEND_SAR_DEADLINE_EVENT = "extend_sar_deadline".freeze
  REMOVE_SAR_EXTENSION_EVENT = "remove_sar_deadline_extension".freeze
  ADD_MESSAGE_TO_CASE_EVENT = "add_message_to_case".freeze
  ADD_NOTE_TO_CASE_EVENT = "add_note_to_case".freeze
  ANNOTATE_RETENTION_CHANGES = "annotate_retention_changes".freeze
  ANNOTATE_SYSTEM_RETENTION_CHANGES = "annotate_system_retention_changes".freeze

  paginates_per 20

  after_destroy :update_most_recent, if: :most_recent?

  validates :message, presence: true, if: :requires_message?

  jsonb_accessor :metadata,
                 message: :text,
                 filenames: [:string, { array: true, default: [] }],
                 final_deadline: :date,
                 linked_case_id: :integer,
                 original_final_deadline: :date

  belongs_to :acting_user, class_name: "User"
  belongs_to :acting_team, class_name: "Team"
  belongs_to :target_user, class_name: "User"
  belongs_to :target_team, class_name: "Team"

  scope :accepted,          -> { where to_state: "drafting"  }
  scope :drafting,          -> { where to_state: "drafting"  }
  scope :messages,          -> { where(event: ADD_MESSAGE_TO_CASE_EVENT).order(:id) }
  scope :responded,         -> { where event: "respond" }
  scope :further_clearance, -> { where event: "request_further_clearance" }

  scope :case_history, -> { where.not(event: ADD_MESSAGE_TO_CASE_EVENT) }

  def record_state_change(kase)
    kase.update!(current_state: to_state, last_transitioned_at: created_at)
  end

  def self.next_sort_key(kase)
    n = kase.transitions.order(sort_key: :desc).limit(1).pluck(:sort_key).singular_or_nil
    n.nil? ? 20 : n + 20
  end

  def self.unset_most_recent(kase)
    transition = kase.transitions.most_recent
    transition.update!(most_recent: false) unless transition.nil?
  end

private

  def update_most_recent
    last_transition = self.case.transitions.order(:sort_key).last
    return if last_transition.blank?

    last_transition.update_column(:most_recent, true)
  end

  def requires_message?
    [
      ADD_MESSAGE_TO_CASE_EVENT,
      ADD_NOTE_TO_CASE_EVENT,
      ANNOTATE_RETENTION_CHANGES,
      ANNOTATE_SYSTEM_RETENTION_CHANGES,
    ].include? event
  end
end
