# Registers email logging interceptor and instrumentation
Rails.application.config.after_initialize do
  # Register interceptor to log emails before delivery
  ActionMailer::Base.register_interceptor(EmailLoggingInterceptor)

  # Subscribe to delivery events to update log with success/failure
  ActiveSupport::Notifications.subscribe("deliver.action_mailer") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    message_id = event.payload[:message_id]

    log = EmailLog.find_by(reference_id: message_id)
    next unless log

    if event.payload[:exception]
      log.fail!(
        "#{event.payload[:exception].first}: #{event.payload[:exception].last}",
        duration: event.duration,
      )
    else
      log.complete!(duration: event.duration)
    end
  rescue StandardError => e
    Rails.logger.error("Email instrumentation failed: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
  end
end
