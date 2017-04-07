# == Schema Information
#
# Table name: case_transitions
#
#  id          :integer          not null, primary key
#  event       :string
#  to_state    :string           not null
#  metadata    :jsonb
#  sort_key    :integer          not null
#  case_id     :integer          not null
#  most_recent :boolean          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class CaseTransition < ActiveRecord::Base
  belongs_to :case, inverse_of: :transitions

  after_destroy :update_most_recent, if: :most_recent?

  jsonb_accessor :metadata,
    user_id:            :integer,
    responding_team_id: :integer,
    managing_team_id:   :integer,
    message:            :text,
    filenames:          [:string, array: true, default: []]

  belongs_to :user
  belongs_to :responding_team, class_name: Team
  belongs_to :managing_team, class_name: Team

  scope :accepted,  -> { where to_state: 'drafting'  }
  scope :drafting,  -> { where to_state: 'drafting'  }
  scope :responded, -> { where to_state: 'responded' }

  private

  def update_most_recent
    last_transition = self.case.transitions.order(:sort_key).last
    return unless last_transition.present?
    last_transition.update_column(:most_recent, true)
  end
end
