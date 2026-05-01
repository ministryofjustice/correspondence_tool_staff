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
  FAILURE_STATUSES = %w[permanent-failure temporary-failure technical-failure].freeze

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
  after_commit :publish_email_queued_event, on: :create
  after_commit :publish_delivery_status_event, on: :update, if: :saved_change_to_status?

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

  def publish_email_queued_event
    publish_email_lifecycle_event(Events::EmailQueued)
  end

  def publish_delivery_status_event
    previous_status, current_status = saved_change_to_status
    return if previous_status == current_status

    event_class = case current_status
                  when "delivered"
                    Events::EmailDelivered
                  when *FAILURE_STATUSES
                    Events::EmailFailed
                  end

    return if event_class.nil?

    publish_email_lifecycle_event(
      event_class,
      previous_status:,
      status: current_status,
    )
  end

  def publish_email_lifecycle_event(event_class, extra_payload = {})
    Rails.configuration.event_store.publish(
      event_class.new(data: system_log_email_payload.merge(extra_payload).compact),
    )
  end

  def system_log_email_payload
    {
      category: "commissioning_document",
      email_type:,
      recipient: email_address,
      recipient_type: "external",
      case_id: kase&.id,
      case_number: kase&.number,
      data_request_area_id:,
      data_request_email_id: id,
      notify_id:,
      status:,
      subject: email_subject,
      chase_number:,
    }.compact
  end

  def kase
    data_request_area&.kase
  end

  def email_subject
    return commissioning_email_subject if commissioning_email?
    return chase_email_subject if chase? || chase_escalation? || chase_overdue?

    nil
  end

  def commissioning_email_subject
    request_document = data_request_area&.commissioning_document&.decorate&.request_document
    ["Subject Access Request", kase&.number, request_document, kase&.subject_full_name].compact.join(" - ")
  end

  def chase_email_subject
    return if kase.blank? || chase_number.blank?

    "Subject Access Request - #{kase.number} - #{kase.subject_full_name} - Chase #{chase_number}"
  end

  def notify_client
    @notify_client ||= Notifications::Client.new(Settings.govuk_notify_api_key)
  end
end
