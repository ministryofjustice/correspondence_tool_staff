# == Schema Information
#
# Table name: cases_users_transitions_trackers
#
#  id                 :integer          not null, primary key
#  case_id            :integer
#  user_id            :integer
#  case_transition_id :integer
#

class CasesUsersTransitionsTracker < ActiveRecord::Base
  belongs_to :case
  belongs_to :user

  validates :user_id, uniqueness: { scope: :case_id }

  class << self
    def sync_for_case_and_user(kase, user)
      latest_transition_id = kase.message_transitions.pluck(:id).last
      if latest_transition_id.present?
        tracker = find_by case: kase, user: user
        if tracker
          tracker.update case_transition_id: latest_transition_id
        else
          create case: kase,
                 user: user,
                 case_transition_id: latest_transition_id
        end
      end
    end
  end

  def is_up_to_date?
    last_transition_id = self.case.message_transitions.pluck(:id).last

    if case_transition_id.present?
      last_transition_id.present? &&
        self.case_transition_id >= last_transition_id
    else
      last_transition_id.nil?
    end
  end
end
