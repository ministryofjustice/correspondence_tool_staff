# == Schema Information
#
# Table name: assignments
#
#  id              :integer          not null, primary key
#  assignment_type :enum
#  state           :enum             default("pending")
#  case_id         :integer
#  assignee_id     :integer
#  assigner_id     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Assignment < ApplicationRecord

  validates :assignment_type, :state, :case, :assigner, :assignee,
    presence: true

  enum state: {
    pending: 'pending', rejected: 'rejected', accepted: 'accepted'
  }

  enum assignment_type: {
    caseworker: 'caseworker', drafter: 'drafter'
  }

  belongs_to :case
  belongs_to :assigner, class_name: 'User'
  belongs_to :assignee, class_name: 'User'

  attr_accessor :reasons_for_rejection

  def reject(message)
    event = case assignment_type
            when 'drafter' then :responder_assignment_rejected
            end
    self.case.send(event, assignee_id, message)
    self.delete
  end

  def accept
    event = case assignment_type
            when 'drafter' then :responder_assignment_accepted
            end
    self.case.send(event, assignee_id)
    accepted!
  end
end
