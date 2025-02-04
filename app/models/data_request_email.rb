# == Schema Information
#
# Table name: data_request_emails
#
#  id                   :bigint           not null, primary key
#  data_request_id      :bigint
#  email_type           :integer          default("commissioning_email")
#  email_address        :string
#  notify_id            :string
#  status               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  data_request_area_id :bigint
#  chase_number         :integer
#
class DataRequestEmail < ApplicationRecord
  belongs_to :data_request
  belongs_to :data_request_area

  validates :data_request_area, presence: true
  validates :email_address, presence: true
  validates :status, presence: true

  enum :email_type, {
    commissioning_email: 0,
    chase: 1,
    chase_escalation: 2,
    chase_overdue: 3,
  }

  attribute :status, default: "created"

  after_create :update_status_with_delay

  scope :recent, -> { where("created_at >= ?", Time.zone.today - 7) }
  scope :sent_to_notify, -> { where.not(notify_id: nil) }
  scope :delivering, -> { recent.sent_to_notify.where(status: %w[created sending]) }

  def update_status_with_delay(delay: 15.seconds)
    EmailStatusJob.set(wait: delay).perform_later(id)
  end

  def update_status!
    return if DataRequestEmail.delivering.where(id:).empty?

    response = notify_client.get_notification(notify_id)
    update!(status: response.status)
  end

private

  def notify_client
    @notify_client ||= Notifications::Client.new(Settings.govuk_notify_api_key)
  end
end
