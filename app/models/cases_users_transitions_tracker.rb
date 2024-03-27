# == Schema Information
#
# Table name: cases_users_transitions_trackers
#
#  id                 :integer          not null, primary key
#  case_id            :integer
#  user_id            :integer
#  case_transition_id :integer
#  created_at         :datetime
#  updated_at         :datetime
#
# This model is meant to track which messages have been
# viewed by users, so that we can show a message bubble telling
# them that they have not seen everything on a case.
# The field 'case_trasition_id' reflects the last message
# a particular user has looked at.
class CasesUsersTransitionsTracker < ApplicationRecord
  belongs_to :case,
             class_name: "Case::Base"

  belongs_to :user

  validates :user_id, uniqueness: { scope: :case_id }

  class << self
    def sync_for_case_and_user(kase, user)
      latest_transition = kase.message_transitions.last
      if latest_transition.present?
        tracker = find_by(case: kase, user:)
        if tracker
          # Pretty sure this can't fail, but its a good pattern to use ! methods
          tracker.update! case_transition_id: latest_transition.id
        else
          create! case: kase,
                  user:,
                  case_transition_id: latest_transition.id
        end
      end
    end
  end

  def is_up_to_date?
    last_transition_id = self.case.message_transitions.pluck(:id).last

    if case_transition_id.present?
      last_transition_id.present? &&
        case_transition_id >= last_transition_id
    else
      last_transition_id.nil?
    end
  end
end
