class RequestPersonalInformationJob < ApplicationJob
  queue_as :rpi

  # Assume PersonalInformationRequest was already created on receipt of submission from service provider e.g. MOJ-Forms.
  def perform(id, data)
    SentryContextProvider.set_context
    request = nil

    begin
      request = PersonalInformationRequest.find_by(id: id)
      if request.nil?
        request = PersonalInformationRequest.build(data)
        request.save!
      else
        request.build(data)
      end

      request.targets.each do |target|
        ActionNotificationsMailer.rpi_email(request, target).deliver_later
      end

      request.completed
    rescue StandardError => e
      request&.failed(e)
      Sentry.capture_exception(e)
    end
  end
end
