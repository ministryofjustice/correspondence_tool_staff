# == Schema Information
#
# Table name: case_transitions
#
#  id             :integer          not null, primary key
#  event          :string
#  to_state       :string           not null
#  metadata       :jsonb
#  sort_key       :integer          not null
#  case_id        :integer          not null
#  most_recent    :boolean          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  acting_user_id :integer
#  acting_team_id :integer
#  target_user_id :integer
#  target_team_id :integer
#

class CaseTransition < ActiveRecord::Base
  belongs_to :case, inverse_of: :transitions

  after_destroy :update_most_recent, if: :most_recent?

  validates :message, presence: true, if: -> { event == 'add_message_to_case' }

  jsonb_accessor :metadata,
                 message:        :text,
                 filenames:      [:string, array: true, default: []],
                 final_deadline: :date,
                 linked_case_id: :integer

  belongs_to :acting_user, class_name: User
  belongs_to :acting_team, class_name: Team
  belongs_to :target_user, class_name: User
  belongs_to :target_team, class_name: Team

  scope :accepted,          -> { where to_state: 'drafting'  }
  scope :drafting,          -> { where to_state: 'drafting'  }
  scope :messages,          -> { where(event: 'add_message_to_case').order(:id) }
  scope :responded,         -> { where event: 'respond' }
  scope :further_clearance, -> { where event: 'request_further_clearance' }

  scope :case_history, -> { where.not(event: ['add_message_to_case',
                                             'flag_for_clearance',
                                             'unflag_for_clearance'])}

  def record_state_change(kase)
    kase.update!(current_state: self.to_state, last_transitioned_at: self.created_at)
  end

  private

  def update_most_recent
    last_transition = self.case.transitions.order(:sort_key).last
    return unless last_transition.present?
    last_transition.update_column(:most_recent, true)
  end
end
