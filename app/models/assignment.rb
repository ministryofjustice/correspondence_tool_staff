class Assignment < ApplicationRecord

  validates :assignment_type, :state, :correspondence, :assigner, :assignee,
    presence: true

  enum state: {
    pending: 'pending', rejected: 'rejected', accepted: 'accepted'
  }

  enum assignment_type: {
    caseworker: 'caseworker', drafter: 'drafter'
  }

  belongs_to :correspondence
  belongs_to :assigner, class_name: 'User'
  belongs_to :assignee, class_name: 'User'

  after_create :update_correspondence

  private

  def update_correspondence
    correspondence.update(state: 'awaiting_drafter')
  end

end
