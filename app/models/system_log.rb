# == Schema Information
#
# Table name: system_logs
#
#  id            :bigint           not null, primary key
#  type          :string           not null
#  status        :string           default("pending")
#  reference_id  :string
#  action        :string
#  source        :string
#  metadata      :jsonb            default({})
#  error_message :text
#  duration_ms   :float
#  completed_at  :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class SystemLog < ApplicationRecord
  scope :recent, -> { order(created_at: :desc).limit(500) }
  scope :pending, -> { where(status: "pending") }
  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }

  validates :type, presence: true

  def complete!(duration: nil)
    update!(status: "success", completed_at: Time.current, duration_ms: duration)
  end

  def fail!(message, duration: nil)
    update!(status: "failed", error_message: message, duration_ms: duration)
  end
end
