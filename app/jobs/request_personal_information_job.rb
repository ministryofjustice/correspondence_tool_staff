class RequestPersonalInformationJob < ApplicationJob
  queue_as :rpi

  def perform(data)
    SentryContextProvider.set_context
    request = PersonalInformationRequest.build(data)
    request.save!
    request.targets.each do |target|
      ActionNotificationsMailer.rpi_email(request, target).deliver_later
    end
  end
end
