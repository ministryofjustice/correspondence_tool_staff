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
  validates :reasons_for_rejection, presence: true, if: -> { self.rejected? }
  validate :approved_only_for_approvals

  enum state: {
         pending: 'pending',
         rejected: 'rejected',
         accepted: 'accepted',
       }
  enum role: {
         managing: 'managing',
         responding: 'responding',
         approving: 'approving',
       }

  belongs_to :case
  belongs_to :team
  belongs_to :user

  scope :approved, -> { where(approved: true) }
  scope :unapproved, -> { where(approved: false) }
  scope :for_user, -> (user) { where(user: user) }
  scope :with_teams, -> (teams) do
    where(team: teams, state: ['pending', 'accepted'])
  end
  scope :for_team, -> (team) { where(team: team) }

  scope :last_responding, -> {
    responding.where.not(state: 'rejected').order(id: :desc).limit(1)
  }

  attr_accessor :reasons_for_rejection

  def reject(rejecting_user, message)
    self.reasons_for_rejection = message
    self.case.responder_assignment_rejected(rejecting_user, team, message)
    rejected!
  end

  def accept(accepting_user)
    self.case.responder_assignment_accepted(accepting_user, team)
    self.user = accepting_user
    self.accepted!
  end

  def assign_and_validate_state(state)
    assign_attributes(state: state)
    valid?
  end

  private

  def approved_only_for_approvals
    if approved? && role != 'approving'
      errors.add(:approved, 'true')
    end
  end
end
