# == Schema Information
#
# Table name: assignments
#
#  id         :integer          not null, primary key
#  state      :enum             default("pending")
#  case_id    :integer          not null
#  team_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  role       :enum
#  user_id    :integer
#  approved   :boolean          default(FALSE)
#

class Assignment < ApplicationRecord
  validates :case, :role, :state, :team, presence: true
  validates :reasons_for_rejection, presence: true, if: -> { rejected? }
  validate :approved_only_for_approvals
  validate :unique_pending_responder

  enum :state, {
    pending: "pending",
    rejected: "rejected",
    accepted: "accepted",
    bypassed: "bypassed",
  }
  enum :role, {
    managing: "managing",
    responding: "responding",
    approving: "approving",
  }

  belongs_to :case,
             inverse_of: :assignments,
             class_name: "Case::Base"

  belongs_to :team

  belongs_to :user

  scope :approved, -> { where(approved: true) }
  scope :unapproved, -> { where(approved: false) }
  scope :for_user, ->(user) { where(user:) }
  scope :with_teams, lambda { |teams|
    where(team: teams, state: %w[pending accepted])
  }
  scope :for_team, ->(team) { where(team:) }

  scope :pending_accepted, -> { where(state: %w[pending accepted]) }

  scope :flagged_for_approval, lambda { |teams|
    where(team: teams, role: "approving")
  }

  scope :team_restriction, lambda { |user_id, role|
    joins("join teams_users_roles on assignments.team_id=teams_users_roles.team_id")
    .where('teams_users_roles': { user_id:, role: role.to_s })
    .where.not(state: [:rejected])
    .select(:case_id).distinct
  }

  # Putting a 'limit 1' here breaks the caching of Case::Base#responder_assignment
  # please treat this as a 'private' method i.e. don't use it in application code
  # obviously it can't be actually private due to the usage in Case::Base#responder_assignment
  scope :last_responding, lambda {
    responding.where.not(state: "rejected").order(id: :desc)
  }

  attr_accessor :reasons_for_rejection

  before_save :mark_case_as_dirty_for_responding_assignments

  def reject(rejecting_user, message)
    self.reasons_for_rejection = message
    self.case.responder_assignment_rejected(rejecting_user, team, message)
    rejected!
  end

  def accept(accepting_user)
    self.case.responder_assignment_accepted(accepting_user, team)
    self.user = accepting_user
    accepted!
  end

  def assign_and_validate_state(state)
    assign_attributes(state:)
    valid?
  end

private

  def mark_case_as_dirty_for_responding_assignments
    if responding? && (new_record? || state_changed_to_rejected_or_bypassed?)
      self.case.mark_as_dirty!
      SearchIndexUpdaterJob.set(wait: 10.seconds).perform_later(self.case.id)
    end
  end

  def state_changed_to_rejected_or_bypassed?
    changed.include?("state") && state.in?(%w[rejected bypassed])
  end

  def unique_pending_responder
    if self.case && (state == "pending" && role == "responding")
      num_existing = self.case.assignments&.responding&.pending&.size
      if num_existing > 1
        errors.add(:role, "responding not unique")
      end
    end
  end

  def approved_only_for_approvals
    if approved? && role != "approving"
      errors.add(:approved, "true")
    end
  end
end
