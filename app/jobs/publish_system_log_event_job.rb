class PublishSystemLogEventJob < ApplicationJob
  queue_as :system_log_events

  def perform(event_class, data:)
    Rails.configuration.event_store.publish(
      event_class.new(data: data.deep_symbolize_keys),
    )
  end
end
