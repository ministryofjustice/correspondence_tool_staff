# Intercepts all outgoing emails and creates an EmailLog record before delivery
class EmailLoggingInterceptor
  def self.delivering_email(message)
    EmailLog.create_from_message(message)
  rescue StandardError => e
    # Don't let logging failures prevent email delivery
    Rails.logger.error("EmailLoggingInterceptor failed: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
  end
end
