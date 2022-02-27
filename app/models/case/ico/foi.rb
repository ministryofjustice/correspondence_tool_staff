# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  delivery_method      :enum
#  workflow             :string
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

class Case::ICO::FOI < Case::ICO::Base

  def self.decorator_class
    Case::ICO::FOIDecorator
  end

  def original_case_type; 'FOI' end

  def has_overturn?
    linked_cases.pluck(:type).include?('Case::OverturnedICO::FOI')
  end

  def ico_foi?
    return true
  end

  def clear_responding_assignment
    self.responder_assignment.destroy()
  end

  def reset_responding_assignment_flag
    self.responder_assignment.update(state: 'pending')
  end

end
