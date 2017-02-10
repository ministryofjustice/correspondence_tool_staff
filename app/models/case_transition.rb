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
  belongs_to :kase,
    inverse_of:  :transitions,
    class_name:  'Case',
    foreign_key: :case_id

  after_destroy :update_most_recent, if: :most_recent?

  jsonb_accessor :metadata,
    user_id:     :integer,
    assignee_id: :integer,
    message:     :text,
    assignment_id: :integer,
    filenames:   [:string, array: true, default: []]

  private

  def update_most_recent
    last_transition = kase.transitions.order(:sort_key).last
    return unless last_transition.present?
    last_transition.update_column(:most_recent, true)
  end
end
