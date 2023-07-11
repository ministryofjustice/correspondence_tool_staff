class DataRequestEmail < ApplicationRecord
  belongs_to :data_request

  validates :data_request, presence: true
  validates :email_address, presence: true
  validates :status, presence: true

  enum email_type: { commissioning_email: 0 }

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
