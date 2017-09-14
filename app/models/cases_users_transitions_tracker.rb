class CasesUsersTransitionsTracker < ActiveRecord::Base
  belongs_to :case
  belongs_to :user

  class << self
    def sync_for_case_and_user(kase, user)
      tracker = find_or_create_by case: kase, user: user
      latest_transition_id = kase.transitions.pluck(:id).last
      if tracker
        tracker.update case_transition_id: latest_transition_id
      else
        create case: kase,
               user: user,
               case_transition_id: latest_transition_id
      end
    end
  end

  def is_up_to_date?
    self.case_transition_id.present? &&
      self.case_transition_id >= self.case.transitions.pluck(:id).last
  end
end
