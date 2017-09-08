class CasesUsersTransitionsTracker < ActiveRecord::Base
  belongs_to :case
  belongs_to :user

  class << self
    def update_tracker_for(case:, user:)
      cutt = CasesUsersTransitionsTracker.find_or_create_by(kase, user)
      cutt.bring_up_to_date
    end
  end

  def is_up_to_date?
    self.case_transition_id >= current_case_transition_id
  end

  def bring_up_to_date
    update case_transition_id: current_case_transition_id
  end

  private

  def current_case_transition_id
    self.case.transitions.pluck(:id).last
  end
end
