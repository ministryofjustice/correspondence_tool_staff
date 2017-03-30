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

  scope :managing,   -> { where(role: 'managing') }
  scope :responding, -> { where(role: 'responding') }

  attr_accessor :reasons_for_rejection

  def reject(current_user, message)
    self.case.responder_assignment_rejected(current_user, team, message)
    self.delete
  end

  def accept(current_user)
    self.case.responder_assignment_accepted(current_user, team)
    accepted!
  end

  def assign_and_validate_state(state)
    assign_attributes(state: state)
    valid?
  end
end
