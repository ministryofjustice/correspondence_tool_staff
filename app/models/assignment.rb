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


  after_create :update_case
  after_update :update_case

  attr_accessor :reasons_for_rejection

  private

  def update_case
    if self.pending?
      self.case.update(state: 'awaiting_drafter')
    elsif self.accepted?
      self.case.update(state: 'drafting')
    elsif self.rejected?
      self.case.update(state: 'unassigned')
    end
  end
end
