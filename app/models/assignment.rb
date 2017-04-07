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
#

class Assignment < ApplicationRecord
  validates :case, :role, :state, :team, presence: true
  validates :reasons_for_rejection, presence: true, if: -> { self.rejected? }

  enum state: {
         pending: 'pending',
         rejected: 'rejected',
         accepted: 'accepted',
       }
  enum role: {
         managing: 'managing',
         responding: 'responding',
       }

  belongs_to :case
  belongs_to :team
  belongs_to :user

  attr_accessor :reasons_for_rejection

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
    assign_attributes(state: state)
    valid?
  end
end
