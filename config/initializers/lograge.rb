Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.custom_payload do |controller|
    {
      user_id: controller.current_user.try(:id),
      user_email: controller.current_user.try(:email),
      session_id: controller.request.session.id,
      host: controller.request.host,
      tags: %w[request],
      remote_ip: controller.request.remote_ip,

    }
  end
end
