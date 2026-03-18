class RequestPersonalInformationJob < ApplicationJob
  queue_as :rpi

  def perform(request_id)
    SentryContextProvider.set_context
    request = PersonalInformationRequest.find(request_id)

    request.targets.each do |target|
      ActionNotificationsMailer.rpi_email(request, target).deliver_later
    end

    request.update!(processed: true)
  end
end
